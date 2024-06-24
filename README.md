
# Unbalance

Unbalance is a script designed for MergerFS users who also utilize SnapRAID. It ensures that a specified path of data resides on a single disk in the pool. 

I wrote unblance to help migrate from an `mfs` create strategy to `epmfs` such that I could start using SnapRAID and never worry about hitting this quirk: 

* https://sourceforge.net/p/snapraid/discussion/1677233/thread/8282fcf886/?limit=25#b71e/a288/884a/1d58.
* https://www.reddit.com/r/Snapraid/comments/1clk039/comment/l2zk8t3/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

## Features
- Ensures a specified path is located on only one disk.
- Automatically scans disks in the pool to find the largest existing data path.
- Moves data to the largest disk, if needed.
- Provides clear logging and operation status updates.

## Installation
0. Make the script executable with `chmod u+x unbalance.sh`
1. Ensure you have `rsync` installed
2. Modify the disk list in `unbalance.sh` to match your mount points. 

```bash
# Configurable Parameters
disks=("/mnt/disk1" "/mnt/disk2" "/mnt/disk3" "/mnt/disk4")  # Array of disk mounts
```

## Usage
Run the script with the partial path you want to un-balance. Do not includ the disk or pool.

**Example:**
```bash
./unbalance.sh "tv/some-show (2024)"
```

### For a path that is already un-balanced, you would see
```bash
Path: tv/show-a (2024)
-------------------
Logs: /home/azohra/unbalance.log (ID: 1MMQ7Y)
-------------------
Path Usage:
/mnt/disk1: Not present
/mnt/disk2: Not present
/mnt/disk3: Not present
/mnt/disk4: 7.2GiB (Largest)
-------------------
Total data to move: 0B
-------------------
Current operation: Checking data balance
-------------------
Recent Logs:
  [2024-06-23 19:37:24] [1MMQ7Y] 🟢 Unbalancer started for 'tv/show-a (2024)'
  [2024-06-23 19:37:24] [1MMQ7Y] Starting disk scan for path
  [2024-06-23 19:37:24] [1MMQ7Y] Path not present on /mnt/disk1
  [2024-06-23 19:37:24] [1MMQ7Y] Path not present on /mnt/disk2
  [2024-06-23 19:37:24] [1MMQ7Y] Path not present on /mnt/disk3
  [2024-06-23 19:37:24] [1MMQ7Y] Path present on /mnt/disk4: 7.2GiB
  [2024-06-23 19:37:24] [1MMQ7Y] ✔️ Path is already unbalanced (or does not exist on any disk)
```

### For a path that requires un-balancing, you would see
```bash
Path: tv/show-b (2020)
-------------------
Logs: /home/azohra/unbalance.log (ID: eR4iA0)
-------------------
Path Usage:
/mnt/disk1: 3.6GiB
/mnt/disk2: 8.1GiB
/mnt/disk3: 4.3GiB
/mnt/disk4: 13GiB (Largest)
-------------------
Total data to move: 16GiB
-------------------
Current operation: Checking data balance
-------------------
Recent Logs:
  [2024-06-23 19:57:45] [eR4iA0] 🟢 Unbalance started for 'tv/show-b (2020)'
  [2024-06-23 19:57:45] [eR4iA0] Starting disk scan for path
  [2024-06-23 19:57:45] [eR4iA0] Path present on /mnt/disk1: 3.6GiB
  [2024-06-23 19:57:45] [eR4iA0] Path present on /mnt/disk2: 8.1GiB
  [2024-06-23 19:57:45] [eR4iA0] Path present on /mnt/disk3: 4.3GiB
  [2024-06-23 19:57:45] [eR4iA0] Path present on /mnt/disk4: 13GiB
  [2024-06-23 19:57:45] [eR4iA0] Path is largest on /mnt/disk4 with 13GiB
  [2024-06-23 20:12:55] [eR4iA0] 16GiB of data should move to /mnt/disk4
  [2024-06-23 20:12:58] [eR4iA0] Starting file transfer from /mnt/disk1 to /mnt/disk4
  [2024-06-23 20:13:17] [eR4iA0] Completed file transfer from /mnt/disk1 to /mnt/disk4
  [2024-06-23 20:13:17] [eR4iA0] Removed empty directories from /mnt/disk1:
  [2024-06-23 20:13:17] [eR4iA0] Starting file transfer from /mnt/disk2 to /mnt/disk4
  [2024-06-23 20:14:11] [eR4iA0] Completed file transfer from /mnt/disk2 to /mnt/disk4
  [2024-06-23 20:14:11] [eR4iA0] Removed empty directories from /mnt/disk2:
  [2024-06-23 20:14:11] [eR4iA0] Starting file transfer from /mnt/disk3 to /mnt/disk4
  [2024-06-23 20:14:40] [eR4iA0] Completed file transfer from /mnt/disk3 to /mnt/disk4
  [2024-06-23 20:14:40] [eR4iA0] Removed empty directories from /mnt/disk3:
  [2024-06-23 20:14:40] [k4ca6H] All files for 'tv/show-b (2020)' have been moved to /mnt/disk4
  [2024-06-23 20:14:40] [k4ca6H] ✔️ Path unbalanced successfully
-------------------
```
 
## Logging
All actions are shown in the CLI and also logged to the directory where the script is executed, with the filename `unbalance.log`. The logs include detailed information about each step and operation performed by the script.

## License
This project is licensed under the MIT License.
