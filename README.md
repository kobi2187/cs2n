# cs2n

This project aims to be a complete transpiler from the C# language to Nim.
A sibling project is CsDisplay. It is needed in order to get the input;
We use the Roslyn parser, creating json files -- the so called .csast files.
Then on the Nim side, we read such a file or a folder with such files, 
and from these we create a tree of all the constructs and their relations to each other (such as parent child relations)
After all the constructs and all this information is stored, there comes the generation stage.
We generate Nim code as text instead of Nim nodes, since it seemed easier to do.
Most semantics in C# has a direct mapping in Nim.
With some of the new C# constructs in the recent language versions (6-7-8), I am not very familiar,
therefore not sure how best to translate them.
There are a few utils for code indentation, open/close block, etc.
The design is built in a way that the constructs are easy to add or generate.
when we iterate over the json files, we need to find the parent. 
This is customizable and can be fixed or edited if the solution is not complete.
There are add methods, and gen methods. almost one for each combination I could find with a large code base.
We can simplify some of them, but with a direct approach, although the code seems bloated, it is easy to change or modify, according to the runtime dispatch.
It's not so pretty but a language is complex, and it seems better this way, in terms of maintainability and managing added complexity.
Lastly, there are tools, that I used to quickly identify missing constructs, find c# examples for adding a child to a parent, and find the lowest hanging fruits, that is, libraries that are only missing a single construct implementation to be completely ported.
There are some unit tests, but mostly I took the monotests from the mono project, as they are small and comprehensive.
Some tests are for experimental C# features, so it may only work with the latest Roslyn (in CsDisplay), or these were ignored or deleted (as they confused the parent-finding algorithm).
