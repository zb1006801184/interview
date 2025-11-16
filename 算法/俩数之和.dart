void main(List<String> args) {
  start();
}

/*
 题目：
1. 两数之和


给定一个整数数组 nums 和一个整数目标值 target，请你在该数组中找出 和为目标值 target  的那 两个 整数，并返回它们的数组下标。

你可以假设每种输入只会对应一个答案，并且你不能使用两次相同的元素。

你可以按任意顺序返回答案。



示例 1：

输入：nums = [2,7,11,15], target = 9
输出：[0,1]
解释：因为 nums[0] + nums[1] == 9 ，返回 [0, 1] 。
示例 2：

输入：nums = [3,2,4], target = 6
输出：[1,2]
示例 3：

输入：nums = [3,3], target = 6
输出：[0,1]

提示：

2 <= nums.length <= 104
-109 <= nums[i] <= 109
-109 <= target <= 109
只会存在一个有效答案
*/
void start() {
  List<int> nums = [2, 11, 21, 7];
  int target = 9;
  List<int> result = twoSum(nums, target);
  print(result);
}

/*
答案思路：
使用哈希表存储数组中的元素和它们的索引，
遍历数组时，计算目标值与当前元素的差值，
如果差值在哈希表中存在，则返回差值的索引和当前元素的索引。
*/

List<int> twoSum(List<int> nums, int target) {
  Map<int, int> map = {};
  for (int i = 0; i < nums.length; i++) {
    int complement = target - nums[i];
    if (map.containsKey(complement)) {
      return [map[complement]!, i];
    }
    map[nums[i]] = i;
  }
  return [];
}
