
# Order-To-Cash Process
## WHAT IS IT?

This model simulates the Order-To-Cash process of a supply chain by using the main actors involved in the process. It illustrates how varying certain variables in the supply chain can significantly affect an order fulfillment time.

## HOW IT WORKS

To initiate the simulation the user is allowed to select the number of orders to be processed for each type, the number of agents on each role, the processing type of each agent, the initial efficiency of the agents, the prioritization criteria, and the chance of error.

## HOW TO USE IT

### Buttons
SETUP - sets the supply chain and clears plots
GO - runs the simulation till all the orders are completed

### Sliders
MAKE-TO-ORDER - Number of requests of the type

MAKE-TO-STOCK - Number of requests of the type

AGENT-TOTAL* - Number of agents in this role

DIST-AMOUNT - Initial amount of inventory in distribution center

PRIORITIZE-TYPE - Availability or Expertise

PROCESSING-TYPE-AGENT*:
<ul>
<li>FIFO: FIRST-IN-FIRST-OUT</li>
<li>LIFO: LAST-IN-FIRST-OUT</li>
<li>RAPID RESPONSE: PROCESS SMALLEST ORDERS FIRST</li>
<li>COMPLICATED: PROCESS LARGEST ORDERS FIRST</li>
</ul>

AGENT-EFFICIENCY* - Initial efficiency of the agent

ERROR-PERCENT - Chance of errors in the simulation

*AGENT = Rep, Planner, Plant, Spec, Carrier.



## THINGS TO NOTICE

Run the model with default settings and record the efficiency of the simulation. Find the bottlenecks of the system. Which variables of the model could significantly improved the average fulfillment time of an order?

## THINGS TO TRY

Increase the number of orders (MAKE-TO-ORDER or MAKE-TO-STOCK) to analyze the performance of the model in a high-demand scenario.

Duplicate the number of agents on certain roles to find bottleneck agents.

Change the processing-type of the agents to study which queue management strategy is the most suitable for the model.

Which prioritization type could give better results, availability or expertise?

Is the initial efficiency of the agents relevant throughout the simulation? Is there a point where the agents will perform the same?

How does the chance for error affects the overall performance of the simulation?

## EXTENDING THE MODEL

Incorporate multiple customers with a different order-creation rate such as Poisson distribution.

Model a manufacturing plant with more complexity such as including technicians, plant failures, and scheduling of orders.


## CREDITS AND REFERENCES

Technical report for this model can be found at:
http://www.casos.cs.cmu.edu/publications/papers/CMU-ISR-17-113.pdf

BibTeX entry to be used in publication:

@article{villarraga_agent-based_2017, address={Pittsburgh, PA}, type={Technical {Report}},
title={Agent-based {Modeling} and {Simulation} for an {Order}-{To}-{Cash} {Process} using {NetLogo}}, number={CMU-ISR-17-113}, institution={Carnegie Mellon University, School of Computer Science, Institute for Software Research}
author={Villarraga, John and Carley, Kathleen M and Wassick, John and Sahinidis, Nikolaos},
year={2017}
}


