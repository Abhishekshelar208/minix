# Viva Question Generation Timeout Fix

## Problem
The Viva Preparation page was timing out when generating questions with the error:
```
TimeoutException after 0:01:30.000000: Future not completed
```

## Root Cause
1. **Insufficient timeout duration**: The API call had a 90-second timeout, which was too short for complex question generation
2. **Large prompt size**: Including extensive project context (problem, solution, roadmap with many tasks) resulted in large prompts
3. **High question count**: Generating 20 detailed questions with comprehensive answers took considerable time

## Solutions Implemented

### 1. Increased Timeout Duration
**File**: `lib/services/viva_service.dart` (line 80)
- **Before**: `timeout(const Duration(seconds: 90))`
- **After**: `timeout(const Duration(minutes: 3))`
- **Reason**: Matches the timeout used in `documentation_service.dart`, which successfully handles similar complex generation tasks

### 2. Optimized Prompt Size
**File**: `lib/services/viva_service.dart` (lines 181-209)
- **Before**: Included up to 10 tasks with full details (title, description, category, priority, estimated hours)
- **After**: 
  - Only includes 5 high-priority tasks (Critical/High priority first)
  - Simplified task information (only title and category)
  - Added progress percentage for better context with less data
- **Impact**: Reduces prompt token count while maintaining relevant context

### 3. Reduced Question Count
**File**: `lib/pages/viva_preparation_page.dart` (line 104)
- **Before**: `count: 20`
- **After**: `count: 15`
- **Reason**: Generates faster while still providing comprehensive coverage

### 4. Added Better Error Handling
**File**: `lib/pages/viva_preparation_page.dart` (lines 131-148)
- Detects timeout errors specifically
- Provides user-friendly error message
- Adds "Retry" button for timeout errors
- Helps users understand the issue and take action

### 5. Improved Logging
**File**: `lib/services/viva_service.dart` (line 69)
- Added prompt size logging (characters and estimated tokens)
- Helps monitor and debug future issues
- Format: `Generated prompt for Gemini API (X chars, ~Y tokens)`

## Testing Recommendations
1. Test question generation with a complex project (many tasks, detailed problem/solution)
2. Monitor the debug logs for prompt size
3. Verify the 3-minute timeout is sufficient
4. Test the retry functionality when timeout occurs

## Additional Notes
- The retry mechanism (3 attempts with exponential backoff) was already in place
- The fix maintains consistency with the `documentation_service.dart` approach
- If timeouts persist, consider further reducing the question count or simplifying the prompt

## Related Files
- `lib/services/viva_service.dart` - Core service with timeout and prompt optimization
- `lib/pages/viva_preparation_page.dart` - UI with improved error handling
- `lib/services/documentation_service.dart` - Reference implementation with 3-minute timeout