from sys import argv
from utils.list import Dim
from collections.vector import DynamicVector,InlinedFixedVector
from random import randint,random_float64,random_ui64
from python import Python

alias ItemCount=16

alias ItemCountHalf=8

alias alfa=10

alias beta=20

alias EpisodesCount=100



alias ItemContainer=SIMD[DType.float64,ItemCount]

alias Backpack=SIMD[DType.float64,ItemCount]

struct Backpacks(CollectionElement):
    
    var pack:Backpack
    var cost:Float64
    var weight:Float64
    var score:Float64

    fn __init__(inout self,item_weight:ItemContainer,item_cost:ItemContainer):
        self.pack=Backpack()
        self.cost=0
        self.weight=0
        self.score=0
        self.generate_backpack(item_weight,item_cost)

    fn __init__(inout self):
        self.pack=Backpack()
        self.cost=0
        self.weight=0
        self.score=0
    
    fn generate_backpack(inout self,item_weight:ItemContainer,item_cost:ItemContainer):

        for i in range(ItemCount):
            self.pack[i]=random_float64(0,1)

            if self.pack[i]<0.5:
                self.pack[i]=0
            else:
                self.pack[i]=1
    
        self.calculate(item_weight,item_cost)

    fn calculate(inout self,item_weight:ItemContainer,item_cost:ItemContainer):
        self.weight=0
        self.cost=0

        let _w=self.pack*item_weight
        let _c=self.pack*item_cost

        for i in range(ItemCount):
            self.weight+=_w[i]
            self.cost+=_c[i]

    fn eval(inout self):
        

        if beta*self.weight >= alfa*self.cost:
            self.score=0
            return

        self.score = alfa*self.cost - beta*self.weight

    fn __copyinit__(inout self,exisiting:Self):
        self.pack=exisiting.pack
        self.cost=exisiting.cost
        self.weight=exisiting.weight
        self.score=exisiting.score

    fn __moveinit__(inout self, owned exisiting: Self):
        self.pack=exisiting.pack
        self.cost=exisiting.cost
        self.weight=exisiting.weight
        self.score=exisiting.score
            


fn generate_backpack(item_weight:ItemContainer)->Backpack:

    var output=Backpack()


    for i in range(ItemCount):
        output[i]=random_float64(0,1)

        if output[i]<0.5:
            output[i]=0
        else:
            output[i]=1
        
    return output


fn print_items(item:ItemContainer):
    @unroll
    for i in range(ItemCount):
        print(item[i])


fn generate_population(owned population:DynamicVector[Backpacks],size:Int,item_weight:ItemContainer,item_cost:ItemContainer)-> DynamicVector[Backpacks]:
    for i in range(size):
        population.append(Backpacks(item_weight,item_cost))

    return population

fn evaluate_population(inout population:DynamicVector[Backpacks]):
    for i in range(len(population)):
        population[i].eval()
        
fn crossover(a:Backpacks,b:Backpacks)->Backpacks:

    var out=Backpacks()

    out.pack= a.pack.shift_left[ItemCountHalf]()+b.pack.shift_right[ItemCountHalf]()

    return out

fn mutate(inout x:Backpacks):

    if random.random_float64(0.0,1.0)>0.1:
        return

    let i:Int=random.random_ui64(0,ItemCount-1).to_int()
    
    x.pack[i]=1-x.pack[i]


@always_inline
fn backpack_swap(inout vector: DynamicVector[Backpacks], a: Int, b: Int):
    let tmp = vector[a]
    vector[a]=vector[b]
    vector[b]=tmp

@always_inline
fn _partition(inout vector: DynamicVector[Backpacks], low: Int, high: Int) -> Int:
    let pivot = vector[high].score
    var i = low - 1
    for j in range(low, high):
        if vector[j].score <= pivot:
            i += 1
            backpack_swap(vector,i,j)
    backpack_swap(vector,i+1,high)
    return i + 1

fn _quick_sort(inout vector: DynamicVector[Backpacks], low: Int, high: Int):
    if low < high:
        let pi = _partition(vector, low, high)
        _quick_sort(vector, low, pi - 1)
        _quick_sort(vector, pi + 1, high)

fn quick_sort(inout vector: DynamicVector[Backpacks]):
    _quick_sort(vector,0,len(vector)-1)


def show_score_plot(score:DynamicVector[Float64],steps:Int):
    
    plt = Python.import_module("matplotlib.pyplot")

    np = Python.import_module("numpy")

    arr = np.zeros(len(score),np.float64)

    for i in range(len(score)):
        arr.itemset(i,score[i])

    plt.xlabel("Episode")
    plt.ylabel("Score")
    plt.plot(arr)
    plt.show()





fn main() raises:

    var item_cost=ItemContainer()
    var item_weight=ItemContainer()

    for i in range(ItemCount):
        item_cost[i]=random_float64(1.0,4.0)
        item_weight[i]=random_float64(0.1,2.0)

    print("Items cost:")
    print_items(item_cost)

    print("Items weight:")
    print_items(item_weight)

    print("")

    var genomes:DynamicVector[Backpacks]=DynamicVector[Backpacks]()

    var scores:DynamicVector[Float64]=DynamicVector[Float64]()

    var best_option:Backpacks=Backpacks()


    genomes=generate_population(genomes,10,item_weight,item_cost)    

    for i in range(1,EpisodesCount):
        print("Episode: ",i)

        evaluate_population(genomes)

        quick_sort(genomes)

        best_option=genomes[len(genomes)-1]

        # get 4 of best populations member and perform crossover

        print("Best result:")
        print("Cost: ",genomes[len(genomes)-1].cost," Weight: ",genomes[len(genomes)-1].weight)
        print("Score: ",genomes[len(genomes)-1].score)
        scores.append(genomes[len(genomes)-1].score)
        
        var childrens:DynamicVector[Backpacks]=DynamicVector[Backpacks]()

        for o in range(2):
            childrens.append(crossover(genomes[len(genomes)-1 - 2*o],genomes[len(genomes)-1 - (2*o + 1)]))
            childrens.append(crossover(genomes[len(genomes)-1 - ( 2*o + 1 )],genomes[len(genomes)-1 - 2*o]))    

        for o in range(len(childrens)):
            childrens[o].calculate(item_weight,item_cost)

        childrens.append(Backpacks(item_weight,item_cost))
        childrens.append(Backpacks(item_weight,item_cost))

        for o in range(len(childrens)):
            mutate(childrens[o])

        genomes.clear()

        genomes=childrens

    print("Best configuration:")

    print(best_option.pack)

    show_score_plot(scores,EpisodesCount)
    
