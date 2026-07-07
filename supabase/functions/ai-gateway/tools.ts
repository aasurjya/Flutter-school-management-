// ============================================================================
// supabase/functions/ai-gateway/tools.ts
//
// Read-only tool catalog for the agentic gateway path. Each tool is:
//   • declared with an OpenAI-compatible function definition (forwarded to the
//     model as part of the `tools` array), and
//   • executed server-side by a fixed handler that scopes EVERY query to the
//     caller's tenant_id (taken from the JWT, never from tool args).
//
// Safety invariants (the crux of agentic + multi-tenant):
//   • Tools are READ-ONLY (SELECT only). There is no write tool, by design.
//   • tenant_id is injected server-side; the model's args carry only
//     intra-tenant selectors (student_id, free-text query) — it cannot widen
//     scope to another tenant.
//   • Blank / missing id args are rejected up front (avoids the empty-UUID
//     PostgREST 400 class this codebase has hit before).
//   • Free-text used in PostgREST `.or()` is sanitized to neutralize filter
//     injection. Every result set is LIMITed.
//   • Only tools allow-listed on the feature_route (feature_routes.tools) are
//     ever exposed to the model or executed.
// ============================================================================

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface OpenAiToolDef {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: {
      type: 'object';
      properties: Record<string, unknown>;
      required: string[];
    };
  };
}

export interface ToolDef {
  definition: OpenAiToolDef;
  execute: (
    db: SupabaseClient,
    tenantId: string,
    args: Record<string, unknown>,
  ) => Promise<unknown>;
}

function isBlank(v: unknown): boolean {
  return typeof v !== 'string' || v.trim() === '';
}

/// Strip characters that carry meaning in PostgREST filter syntax so model-
/// supplied free text can't escape its `ilike` clause.
function sanitizeTerm(v: string): string {
  return v.trim().replace(/[^\p{L}\p{N}\s_-]/gu, '').slice(0, 80);
}

function fn(
  name: string,
  description: string,
  properties: Record<string, unknown>,
  required: string[],
): OpenAiToolDef {
  return {
    type: 'function',
    function: { name, description, parameters: { type: 'object', properties, required } },
  };
}

export const TOOL_CATALOG: Record<string, ToolDef> = {
  find_students: {
    definition: fn(
      'find_students',
      'Find students in this school by name or admission number. Returns up to 10 matches, each with the id needed by the other tools.',
      { query: { type: 'string', description: 'Name or admission-number fragment to search for.' } },
      ['query'],
    ),
    execute: async (db, tenantId, args) => {
      if (isBlank(args.query)) return { error: 'query is required' };
      const term = sanitizeTerm(args.query as string);
      if (term === '') return { error: 'query has no searchable characters' };
      const { data, error } = await db
        .from('students')
        .select('id, first_name, last_name, admission_number')
        .eq('tenant_id', tenantId)
        .or(`first_name.ilike.%${term}%,last_name.ilike.%${term}%,admission_number.ilike.%${term}%`)
        .limit(10);
      if (error) return { error: error.message };
      return { students: data ?? [] };
    },
  },

  get_attendance_summary: {
    definition: fn(
      'get_attendance_summary',
      "Summarize a student's recent attendance (last 60 records) as counts per status.",
      { student_id: { type: 'string', description: 'The student id (from find_students).' } },
      ['student_id'],
    ),
    execute: async (db, tenantId, args) => {
      if (isBlank(args.student_id)) return { error: 'student_id is required' };
      const { data, error } = await db
        .from('attendance')
        .select('date, status')
        .eq('tenant_id', tenantId)
        .eq('student_id', args.student_id as string)
        .order('date', { ascending: false })
        .limit(60);
      if (error) return { error: error.message };
      const rows = (data ?? []) as Array<{ status?: string }>;
      const byStatus: Record<string, number> = {};
      for (const r of rows) {
        const s = r.status ?? 'unknown';
        byStatus[s] = (byStatus[s] ?? 0) + 1;
      }
      return { total_records: rows.length, by_status: byStatus };
    },
  },

  get_student_marks: {
    definition: fn(
      'get_student_marks',
      "Get a student's exam marks (obtained vs max), up to 50 most recent subject entries.",
      { student_id: { type: 'string', description: 'The student id (from find_students).' } },
      ['student_id'],
    ),
    execute: async (db, tenantId, args) => {
      if (isBlank(args.student_id)) return { error: 'student_id is required' };
      const { data, error } = await db
        .from('marks')
        .select('marks_obtained, exam_subjects(max_marks, exam_id)')
        .eq('tenant_id', tenantId)
        .eq('student_id', args.student_id as string)
        .limit(50);
      if (error) return { error: error.message };
      const marks = ((data ?? []) as Array<Record<string, unknown>>).map((m) => {
        const es = m.exam_subjects as { max_marks?: unknown; exam_id?: unknown } | null;
        return { obtained: m.marks_obtained ?? null, max: es?.max_marks ?? null };
      });
      return { marks };
    },
  },

  get_fee_status: {
    definition: fn(
      'get_fee_status',
      "Get a student's fee/invoice status: amounts, due dates, and total outstanding.",
      { student_id: { type: 'string', description: 'The student id (from find_students).' } },
      ['student_id'],
    ),
    execute: async (db, tenantId, args) => {
      if (isBlank(args.student_id)) return { error: 'student_id is required' };
      const { data, error } = await db
        .from('invoices')
        .select('total_amount, paid_amount, due_date, status')
        .eq('tenant_id', tenantId)
        .eq('student_id', args.student_id as string)
        .order('due_date', { ascending: true })
        .limit(50);
      if (error) return { error: error.message };
      const rows = (data ?? []) as Array<{ total_amount?: unknown; paid_amount?: unknown }>;
      let outstanding = 0;
      for (const r of rows) {
        outstanding += (Number(r.total_amount) || 0) - (Number(r.paid_amount) || 0);
      }
      return { invoices: rows, total_outstanding: outstanding };
    },
  },
};

/// OpenAI-compatible `tools` array for the allow-listed names (unknown names
/// are silently dropped — the model only ever sees real tools).
export function toolDefsFor(allowed: string[]): OpenAiToolDef[] {
  return allowed.filter((n) => TOOL_CATALOG[n]).map((n) => TOOL_CATALOG[n].definition);
}

/// Execute an allow-listed tool by name. Always returns a JSON-serializable
/// object; never throws (errors are returned as `{ error }` so the model can
/// recover or apologize rather than crashing the loop).
export async function executeTool(
  name: string,
  args: Record<string, unknown>,
  db: SupabaseClient,
  tenantId: string,
  allowed: string[],
): Promise<unknown> {
  if (!allowed.includes(name)) return { error: `tool '${name}' is not allowed for this feature` };
  const tool = TOOL_CATALOG[name];
  if (!tool) return { error: `unknown tool '${name}'` };
  try {
    return await tool.execute(db, tenantId, args ?? {});
  } catch (e) {
    return { error: e instanceof Error ? e.message : String(e) };
  }
}
