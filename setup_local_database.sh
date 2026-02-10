#!/bin/bash

# =============================================
# EduMaster Pro - Local Database Setup Script
# =============================================

set -e  # Exit on error

echo "🚀 EduMaster Pro - Local Database Setup"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is running
echo "📋 Step 1: Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    echo ""
    echo "Please start Docker Desktop and try again."
    echo "On Mac: Open Docker Desktop from Applications"
    echo "On Windows: Start Docker Desktop from Start Menu"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"
echo ""

# Check if in correct directory
if [ ! -d "supabase" ]; then
    echo -e "${RED}❌ Error: Not in project root directory${NC}"
    echo "Please run this script from: /Users/ihub-devs/cascade-projects/School-Management-Flutter"
    exit 1
fi

# Start Supabase
echo "📋 Step 2: Starting Supabase..."
supabase start
echo ""

# Wait for Supabase to be ready
echo "⏳ Waiting for Supabase to be ready..."
sleep 5
echo ""

# Reset database and apply migrations
echo "📋 Step 3: Applying all migrations..."
supabase db reset
echo ""

# Load seed data
echo "📋 Step 4: Loading test users and data..."
if [ -f "supabase/seed_test_users_with_auth.sql" ]; then
    psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed_test_users_with_auth.sql
    echo -e "${GREEN}✅ Test data loaded successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Seed file not found, skipping...${NC}"
fi
echo ""

# Get Supabase URLs
STUDIO_URL="http://localhost:54323"
API_URL="http://localhost:54321"
DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "📊 Supabase Studio: ${STUDIO_URL}"
echo "🔌 API URL: ${API_URL}"
echo "💾 Database URL: ${DB_URL}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: You need to create auth users manually!${NC}"
echo ""
echo "📝 Next Steps:"
echo "1. Open Supabase Studio: ${STUDIO_URL}"
echo "2. Go to Authentication > Users"
echo "3. Click 'Add User' and create users from LOGIN_CREDENTIALS.md"
echo "4. Use email from file and password: Demo@2026"
echo "5. Important: Set correct User ID (UUID) from the file"
echo ""
echo "📚 Documentation:"
echo "- LOGIN_CREDENTIALS.md - All usernames and passwords"
echo "- QUICK_START_GUIDE.md - Developer guide"
echo "- TESTING_SUMMARY.md - Testing procedures"
echo ""
echo "🎉 Happy Testing!"
echo ""
