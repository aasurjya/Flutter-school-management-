// Supabase Edge Function: Compute Exam Statistics
// This function calculates ranks, toppers, and class averages for an exam

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ExamStatistics {
  tenant_id: string
  exam_id: string
  section_id: string
  subject_id?: string
  student_id?: string
  total_marks: number
  obtained_marks: number
  percentage: number
  grade?: string
  rank?: number
  is_class_topper: boolean
  is_subject_topper: boolean
  class_average?: number
  class_highest?: number
  class_lowest?: number
  computed_at?: string
}

serve(async (req: Request) => {
  try {
    const { exam_id, tenant_id }: { exam_id?: string; tenant_id?: string } = await req.json()

    if (!exam_id || !tenant_id) {
      return new Response(
        JSON.stringify({ error: 'exam_id and tenant_id are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get all marks for this exam with student and section info
    const { data: marks, error: marksError } = await supabase
      .from('marks')
      .select(`
        *,
        exam_subject:exam_subjects!inner(
          max_marks,
          subject_id,
          class_id,
          exam:exams!inner(id, name)
        ),
        student:students!inner(
          id,
          first_name,
          last_name,
          enrollment:student_enrollments!inner(section_id)
        )
      `)
      .eq('exam_subject.exam_id', exam_id)
      .eq('tenant_id', tenant_id)

    if (marksError) {
      throw marksError
    }

    // Group marks by section and student
    const sectionData: Record<string, Record<string, {
      student_id: string
      section_id: string
      subjects: { subject_id: string, marks: number, max: number }[]
      total: number
      obtained: number
    }>> = {}

    for (const mark of marks) {
      const sectionId = mark.student.enrollment[0]?.section_id
      const studentId = mark.student.id
      
      if (!sectionId) continue

      if (!sectionData[sectionId]) {
        sectionData[sectionId] = {}
      }

      if (!sectionData[sectionId][studentId]) {
        sectionData[sectionId][studentId] = {
          student_id: studentId,
          section_id: sectionId,
          subjects: [],
          total: 0,
          obtained: 0
        }
      }

      const student = sectionData[sectionId][studentId]
      const marksObtained = mark.is_absent ? 0 : (mark.marks_obtained || 0)
      const maxMarks = mark.exam_subject.max_marks

      student.subjects.push({
        subject_id: mark.exam_subject.subject_id,
        marks: marksObtained,
        max: maxMarks
      })
      student.total += maxMarks
      student.obtained += marksObtained
    }

    // Calculate statistics per section
    const allStats: ExamStatistics[] = []

    for (const [sectionId, students] of Object.entries(sectionData)) {
      const studentList = Object.values(students)
      
      // Calculate percentages and sort by performance
      const studentPerformances = studentList.map(s => ({
        ...s,
        percentage: s.total > 0 ? (s.obtained / s.total) * 100 : 0
      })).sort((a, b) => b.percentage - a.percentage)

      // Calculate class statistics
      const percentages = studentPerformances.map(s => s.percentage)
      const classAverage = percentages.reduce((a, b) => a + b, 0) / percentages.length
      const classHighest = Math.max(...percentages)
      const classLowest = Math.min(...percentages)

      // Create stats for each student with rank
      studentPerformances.forEach((student, index) => {
        const rank = index + 1
        const isClassTopper = rank === 1

        // Overall stats for student
        allStats.push({
          tenant_id,
          exam_id,
          section_id: sectionId,
          student_id: student.student_id,
          total_marks: student.total,
          obtained_marks: student.obtained,
          percentage: Math.round(student.percentage * 100) / 100,
          grade: getGrade(student.percentage),
          rank,
          is_class_topper: isClassTopper,
          is_subject_topper: false,
          class_average: Math.round(classAverage * 100) / 100,
          class_highest: Math.round(classHighest * 100) / 100,
          class_lowest: Math.round(classLowest * 100) / 100
        })

        // Subject-wise stats
        for (const subject of student.subjects) {
          const subjectPercentage = subject.max > 0 
            ? (subject.marks / subject.max) * 100 
            : 0

          // Check if student is subject topper
          const isSubjectTopper = studentPerformances.every(other => {
            const otherSubject = other.subjects.find(s => s.subject_id === subject.subject_id)
            if (!otherSubject) return true
            return subject.marks >= otherSubject.marks
          })

          allStats.push({
            tenant_id,
            exam_id,
            section_id: sectionId,
            subject_id: subject.subject_id,
            student_id: student.student_id,
            total_marks: subject.max,
            obtained_marks: subject.marks,
            percentage: Math.round(subjectPercentage * 100) / 100,
            grade: getGrade(subjectPercentage),
            is_class_topper: false,
            is_subject_topper: isSubjectTopper
          })
        }
      })

      // Class-level summary (no specific student)
      allStats.push({
        tenant_id,
        exam_id,
        section_id: sectionId,
        total_marks: studentPerformances[0]?.total || 0,
        obtained_marks: 0,
        percentage: Math.round(classAverage * 100) / 100,
        is_class_topper: false,
        is_subject_topper: false,
        class_average: Math.round(classAverage * 100) / 100,
        class_highest: Math.round(classHighest * 100) / 100,
        class_lowest: Math.round(classLowest * 100) / 100
      })
    }

    // Upsert all statistics
    const { error: upsertError } = await supabase
      .from('exam_statistics')
      .upsert(allStats, {
        onConflict: 'exam_id,section_id,subject_id,student_id'
      })

    if (upsertError) {
      throw upsertError
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Computed statistics for ${allStats.length} records`,
        stats_count: allStats.length
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error: unknown) {
    console.error('Error computing exam stats:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

function getGrade(percentage: number): string {
  if (percentage >= 90) return 'A+'
  if (percentage >= 80) return 'A'
  if (percentage >= 70) return 'B+'
  if (percentage >= 60) return 'B'
  if (percentage >= 50) return 'C'
  if (percentage >= 40) return 'D'
  return 'F'
}
