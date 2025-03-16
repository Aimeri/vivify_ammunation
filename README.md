# Description
A gunshop script with a configurable cooldown for weapon purchases.

# Preview
https://streamable.com/42y697

# Installation
- Drag and Drop the script into your [standalone] folder if you wish.  Up to you where you place it.
- Run the SQL query listed below to create the gunshop_cooldowns table.
- Edit the config to change the cooldown and weapon prices to your liking.  The cooldown is in seconds.  Default is 1 week.
- Refresh and run the script and restart your server.

# SQL Code:
```
CREATE TABLE IF NOT EXISTS `gunshop_cooldowns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `last_purchased` INT NOT NULL,
    UNIQUE KEY `citizen_item` (`citizenid`, `item`)
);
```
