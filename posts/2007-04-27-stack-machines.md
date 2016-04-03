title: Stack machines
author: astrobunny
imported: true
create_time: 1177616807
category: Tech
tags: []
---
While being a big anime fan is wonderful, its also nice to stray off and nurture other interests as time goes by. I'm sure Nagato will agree.  
Today I shall talk about the very center of my final year university project. My university project consists of creating an emulator for a computer that first years can play around with to learn about how a computer works after you hit the compile button. I'm supposed to emulate a stack machine.  
Now, typical processors you see such as those made by microprocessor giants Intel and AMD are called register machines. These machines typically store numbers in little boxes in the processor and use them. Stack machines however, only have a few long boxes (typically 2) in which they pile up all the numbers that they use and pick them out one by one. Examples of stack machines are the Motorola 68000 and the Java Virtual Machine.  
Yes I know. They are pretty lame compared to the almighty Core Duo and Athlon Processors, but hey its gotta be simple enough for a first year to use right?  
Well, now I'm gonna talk about what I'm really writing. Basically, its gonna be a simple processor where you write some instructions into memory, and the processor will run through them and do exactly what you wrote. Sounds simple?  
Cool! Now, we're going to have a keyboard! This means the CPU needs to wait for your input! Wow. This does mean that we are gonna be needing some sort of interrupt now. Basically, what happens is, when you press a key on your keyboard, the keyboard sends an interrupt to the CPU, or in other words, it taps the shoulder of the CPU saying "hey, mind if you come over here and have a look at this key the user pressed?" and the CPU will stop whatever it is doing for the moment, and come over to see whats going on. The CPU coming over to see what's going on is called "interrupt handling". Basically, every interrupt must be handled, or the machine simply won't work properly. This means there needs to be some kind of table for the CPU to look up to find out what it has to do when a certain interrupt comes in.  
In the olden days when geeks had long hair and were less accepted in society and carved program code on cave walls, these interrupts came in through wires directly connected to the CPU. Things are different today and now the hardware simply sends a message across, and the CPU knows what to do.  
Now how exactly does it know what to do? Well, thats gonna go int owhat instruction set the CPU uses!

