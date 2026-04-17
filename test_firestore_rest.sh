#!/bin/bash

# Test Firestore connection using REST API
# Using the Firebase project from GoogleService-Info.plist

PROJECT_ID="todoapp-399d7"
API_KEY="AIzaSyDq9jUOxc1qNbQWEwbqsx9__e2aPjOV8pM"

echo "🔥 Testing Firestore connection using REST API..."
echo "📋 Project ID: $PROJECT_ID"
echo "🔑 API Key: ${API_KEY:0:20}..."
echo

# Step 1: Sign in anonymously
echo "1️⃣ Signing in anonymously..."
AUTH_RESPONSE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"returnSecureToken": true}')

if echo "$AUTH_RESPONSE" | grep -q "idToken"; then
    ID_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"idToken":"[^"]*"' | cut -d'"' -f4)
    LOCAL_ID=$(echo "$AUTH_RESPONSE" | grep -o '"localId":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Anonymous auth success!"
    echo "👤 Local ID: $LOCAL_ID"
else
    echo "❌ Anonymous auth failed!"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo

# Step 2: Create test document
echo "2️⃣ Creating test document in Firestore..."
DOCUMENT_ID="test-$(date +%s)"
DOCUMENT_DATA="{
  \"fields\": {
    \"id\": {\"stringValue\": \"$DOCUMENT_ID\"},
    \"title\": {\"stringValue\": \"Test Task from REST API\"},
    \"isCompleted\": {\"booleanValue\": false},
    \"priority\": {\"stringValue\": \"high\"},
    \"createdAt\": {\"timestampValue\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\"},
    \"userId\": {\"stringValue\": \"$LOCAL_ID\"}
  }
}"

CREATE_RESPONSE=$(curl -s -X POST "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/todos?documentId=$DOCUMENT_ID" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DOCUMENT_DATA")

if echo "$CREATE_RESPONSE" | grep -q "name"; then
    echo "✅ Document created successfully!"
    echo "📄 Document ID: $DOCUMENT_ID"
else
    echo "❌ Document creation failed!"
    echo "Response: $CREATE_RESPONSE"
    exit 1
fi

echo

# Step 3: Verify document exists
echo "3️⃣ Verifying document exists..."
VERIFY_RESPONSE=$(curl -s "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/todos/$DOCUMENT_ID" \
  -H "Authorization: Bearer $ID_TOKEN")

if echo "$VERIFY_RESPONSE" | grep -q "fields"; then
    echo "✅ Document verification successful!"
    echo "📊 Document data found in Firestore"
    echo "🔗 Full document path: projects/$PROJECT_ID/databases/(default)/documents/todos/$DOCUMENT_ID"
else
    echo "❌ Document verification failed!"
    echo "Response: $VERIFY_RESPONSE"
fi

echo
echo "🎉 Firestore test completed!"
echo "💡 If all steps were successful, your Firebase project and configuration are working correctly."