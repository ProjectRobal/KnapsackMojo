# A simple Knapsack problem program in Mojo

It is a simple program I have written in Mojo. It is using genetic algorithm to find the most optimal set of items to find
good balance between a value of items and the overall backpack weight.

In code there are few aliases to control the behavior of program:

- ItemCount - items count in knapsack
- ItemCountHalf - ItemCount but in half
- alfa - parameter used in score calculation
- beta - parameter used in score calculation
- EpisodeCount - a number of episodes the program is going to run

A score is calcualted like: score = alfa*knapsack_value - beta*knapsack_cost

