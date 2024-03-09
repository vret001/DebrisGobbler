# DebrisGobbler
This module is a drop-in substitute for DebrisService that offers several significant performance and usability improvements.

DebrisGobbler is much faster than DebrisService. While DebrisService iterates through every item during each frame, resulting in up to 1000 iterations per frame or 60,000 iterations per second, this module only checks the nearest item to destruction per frame.

DebrisService has more problems that stem from this poor performance such as a preset limit on the number of debris items it can handle (which is 1000 by default), this causes problems such as Debris being destroyed before their expiry time. It also uses the old Roblox scheduler, which means it’s very inconsistent and will occasionally not clean up items on time (or at all!)

Alongside these performance improvements, this module retains all of the advantages of DebrisService, such as not creating a new thread or coroutine for each new item and not holding onto destroyed items.

To achieve this, the module utilizes a min-heap and some clever strategies to optimize the clearing of debris. The module is also strongly typed and offers some additional features on top of the original DebrisSevice
