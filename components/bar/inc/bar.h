/**
 * @file bar.h
 * @author Matthew Conway 
 * @date 26 07 2018
 * @brief Example zSys component named bar.
 *
 * Here typically goes a more extensive explanation of what the header
 * defines. Doxygens tags are words preceeded by either a backslash @\
 * or by an at symbol @@.
 * @see http://www.github.com
 */

#include <stdio.h>

/**
 * @brief Start the bar component
 *
 * Here is a description of what the function does. This part may refer to any
 * parameters the function requires, like @p zed. A word of code can also be
 * inserted like @return which can be useful when describing what the function
 * returns. 
 * We can also include text verbatim,
 * @verbatim like this@endverbatim
 * Sometimes it is also convenient to include an example of usage:
 * @code
 * barStruct *out = bar_start(zed);
 * printf("something...\n");
 * @endcode
 *
 * @param zed Short description of parameter "zed"
 * @return Describe what the function returns.
 * @see bar_stop
 * @see http://website/
 * @note If the function requires additional notes, put them here
 * @warning If the function requires a warning note, put it here
 */
void bar_start(int zed);

/**
 * @brief Stop the bar component
 *
 * Here is a description of what the function does. It stops the bar component
 *
 * @return void 
 *
 * @see bar_start
 */
void bar_stop(void);

/**
 * @brief A function that's not used (to show that gcov catches a lack of test
 * coverage for the bar component).
 *
 * This function does not do anything useful
 *
 * @return void 
 */
void bar_not_used(void);

