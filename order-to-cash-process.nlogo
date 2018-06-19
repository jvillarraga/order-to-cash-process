;; @ author: John Villarraga
;; @ Last update: July 14th, 2017

;; Global variables for the model
globals[
  ;; Random index for orders
  list_orders

  ;; Changing effects of day/night in the model
  night-time?
  night-hours
  night-day

  ;; Total number of orders
  orders

  ;; Orders completed
  orders-completed

  ;; Variables to be recorded
  rep-avg
  plan-avg
  spec-avg
  carr-avg
  plant-avg
  order-avg
  performance
  performance-nostd
  total-errors
  st-dev

  ;; Exception procedures (last steps of an order)
  exception-procedures

  process-variable

  ;; Inventory cycle
  small-inventory
  large-inventory

  ;; Incomplete orders options
  incomplete-options
  rework-orders
  correct-orders
  return-orders

  ;; Label of agents for signatures
  label-customers
  label-reps
  label-saps
  label-planners
  label-plants
  label-specs
  label-carriers

  ;; Time to end the simulation
  end-simulation?
]

;; Variables for each agent
turtles-own [
  processing-time
  processing-type
  completed?
  days
  index-order
  queue
  order-done
  waiting
  lastorder-time
  incompleteness
  typeof
  type-init
  move?
  efficiency
  learning-steps
  apply-efficiency?
  amount-material
  queue-capacity
  expertise-level
  expertise-required
  urgency
  init-process-time
  return-order?
  signatures
  return-to
  return-from

  time-in
  time-out

]

;; These are the different kind of agents in the model
breed [ customers customer ]
breed [ planners planner ]
breed [ specialists specialist ]
breed [ carriers carrier ]
breed [ reps rep ]
breed [ saps sap]
breed [ envelopes envelope ]
breed [ plants plant]
breed [ dcenters dcenter ]
breed [ trucks truck ]

;; Setting up the world of the simulation
to setup
  clear-all
  setup-patches
  setup-people
  setup-queues
  setup-globals
  setup-info
  setup-inventory
  setup-links
  setup-label
  reset-ticks
end

;; Night time section
to setup-label
  ask patch (0.95 * max-pxcor) (0.75 * max-pycor)
  [ set plabel-color WHITE
    set night-day self ]
end

;; Setting up agents that take part of the process
to setup-people
  ;; This is for creating a human visualization of agents
  ;; This represents the Customer Service Rep
  set-default-shape reps "person"
  let r 0
  while [ r < rep-total ]
  [ create-reps 1
    [ set label(word "rep" (r + 1))
      set color yellow
      set size 1
      set xcor 0 + r
      set ycor 10
      set index-order r
      set queue []
      set order-done []
      set efficiency rep-efficiency / 100
      set learning-steps n-values 3 [false]
      set processing-type processing-type-reps ]
    set r (r + 1)
  ]

  ;; This represents the Planner/scheduler
  set-default-shape planners "person"
  let p 0
  while [ p < planner-total ]
  [ create-planners planner-total
    [ set label(word "planner" (p + 1))
      set color red
      set size 1
      set xcor -8 + p
      set ycor -6
      set index-order p
      set queue []
      set order-done []
      set efficiency planner-efficiency / 100
      set learning-steps n-values 3 [false]
      set processing-type processing-type-plan ]
    set p (p + 1)
  ]

  ;; This represents the Transportation Specialist
  set-default-shape specialists "person"
  let s 0
  while [ s < spec-total ]
  [ create-specialists 1
    [ set label(word "spec" (s + 1))
      set color 33
      set size 1
      set xcor 0 + s
      set ycor -8
      set index-order s
      set queue []
      set order-done []
      set efficiency spec-efficiency / 100
      set learning-steps n-values 3 [false]
      set processing-type processing-type-specs ]
    set s (s + 1)
  ]

  ;; This represents the Carrier
  set-default-shape carriers "person"
  let i 0
  while [ i < carrier-total ]
  [ create-carriers 1
    [ set label(word "carr" (i + 1))
      set color cyan
      set size 1
      set xcor 8 + i
      set ycor -8
      set index-order i
      set queue []
      set order-done []
      set efficiency carrier-efficiency / 100
      set learning-steps n-values 3 [false]
      set processing-type processing-type-carriers ]
    set i (i + 1)
  ]

  ;; This represents the SAP system
  set-default-shape saps "computer workstation"
  create-saps 1 [
    set label "sap"
    set color white
    set size 3
    set queue []
    set order-done []
    set efficiency 1
    set processing-type processing-type-reps
    set learning-steps n-values 3 [true]
    set queue-capacity 1000

  ]

  ;; Customers
  set-default-shape customers "person business"
  create-customers 1 [
    set label "customer"
    set color gray
    set size 1
    set xcor 10
    set ycor 10
    set queue []
    set order-done []
    set queue-capacity 1000
  ]

  set-default-shape plants "factory"
  create-plants 1 [
    set label "plant"
    set color 2
    set size 5
    set xcor -8
    set ycor -12
    set queue []
    set order-done []
    set efficiency plant-efficiency / 100
    set learning-steps n-values 3 [false]
    set processing-type processing-type-plant
    set queue-capacity 1000
  ]

  set-default-shape dcenters "train freight hopper empty"
  create-dcenters 1 [
    set color 36
    set size 4
    set xcor 9
    set ycor -13
    set queue []
    set order-done []
    set queue-capacity 1000
  ]
end

;; This is to set the queue capacity of the agents
to setup-queues
  foreach [label] of turtles with [shape = "person"]
  [ ask turtles with [label = ?]
    [ if efficiency < 0.65 [
        set queue-capacity 10
        set expertise-level "low" ]
      if efficiency >= 0.65 and efficiency < 0.85 [
        set queue-capacity 20
        set expertise-level "medium" ]
      if efficiency >= 0.85 [
        set queue-capacity 40
        set expertise-level "high" ]
    ]
  ]
end

;; Provides initial values for global variables
to setup-globals
  set orders (make-to-order + make-to-stock)

  set dist-amount 200
  set night-time? false
  set list_orders n-values orders [?]

  set night-hours 12                 ;; Assume 12 ticks = 12 hours
  set exception-procedures [ "invoice" "availability" "orderconfirmation" ]

  set small-inventory 50
  set large-inventory 350

  set incomplete-options [ "rework" "correct" "send-back" ]

  set label-customers [label] of customers
  set label-reps [label] of reps
  set label-saps [label] of saps
  set label-planners [label] of planners
  set label-plants [label] of plants
  set label-specs [label] of specialists
  set label-carriers [label] of carriers

  set end-simulation? false
end

;; Creating envelope agents
to setup-info
  let i 0
  let color-for-order white
  while [ i < orders]
  [ let size-for-order (30 + random 20)
    if i >= make-to-order
    [ set color-for-order red
      set size-for-order (10 + random 20) ]
    ;; Setting error for each order
    let error-chance random 100

    set-default-shape envelopes "letter sealed"
    ;; Order request agent
    setup-envelopes color-for-order 10 10 size-for-order i "orderrequest" error-chance

    ;; Order creation agent
    setup-envelopes color-for-order 0 10 0 i "ordercreation" error-chance

    ;; Planned order agent
    setup-envelopes color-for-order 0 0 size-for-order i "plannedorder" error-chance

    ;; Production order agent
    setup-envelopes color-for-order -8 -6 size-for-order i "productionorder" error-chance

    ;; Production schedule agent
    setup-envelopes color-for-order -8 -6 size-for-order i "productionschedule" error-chance

    ;; Order complete agent
    setup-envelopes color-for-order -8 -12 size-for-order i "ordercomplete" error-chance

    ;; Create delivery agent
    setup-envelopes color-for-order 0 0 size-for-order i "createdelivery" error-chance

    ;; Arrange transportation agent
    setup-envelopes color-for-order 0 -8 size-for-order i "arrangetransp" error-chance

    ;; Delivery notice agent
    setup-envelopes color-for-order 8 -8 size-for-order i "deliverynotice" error-chance

    ;; Distribution Center agent
    setup-envelopes color-for-order 8 -8 size-for-order i "distcenter" error-chance

    set-default-shape envelopes "letter opened"
    ;; Availability agent
    setup-envelopes color-for-order 0 0 0 i "availability" error-chance

    ;; Order confirmation agent
    setup-envelopes color-for-order 0 10 0 i "orderconfirmation" error-chance

    ;; Order confirmation agent
    setup-envelopes color-for-order 0 0 0 i "invoice" error-chance

    set i (i + 1)
  ]
end

;; Setup envelopes for the process
;; @ agent-color: color for information agent
;; @ x: xcor
;; @ y: ycor
;; @ process-time: time to process the order
;; @ i: index of order
;; @ typelabel: type of information agent
;; @ error-chance: chance for error
to setup-envelopes [ agent-color x y process-time i typelabel error-chance ]
  create-envelopes 1
  [ set color agent-color
    ifelse x = 10 and y = 10
    [ set hidden? false ]
    [ set hidden? true ]
    set size 1.3
    set xcor x
    set ycor y
    set completed? false
    set processing-time process-time
    set init-process-time process-time
    set index-order i
    set waiting 0
    set incompleteness error-chance
    set urgency (1 + random 99)
    set typeof typelabel
    set type-init typelabel
    set apply-efficiency? false
    set expertise-required (0.3 + random 0.6)
    set return-order? false
    set signatures [["customer"]]
    set move? false ]

end

;; Setup agents related to inventory
;; Centerrequests: Requests made by Distribution center when runs out of inventory
;; Trucks: Source to send inventory to Distribution center
to setup-inventory
  let i 0
  while [i < ((make-to-order + make-to-stock) / 2)] [
    set-default-shape trucks "truck"
    create-trucks 1 [
      set color gray
      set size 1.5
      set xcor -8
      set ycor -14
      set hidden? true
      set completed? false
      set index-order i
      set amount-material 0
    ]
    set i (i + 1)
  ]
end

;; Setup different patches in interface (blue and green sections in model)
to setup-patches
  ask patches with [ pycor < 0 ][set pcolor green]
  ask patches with [ pycor >= 0 ][set pcolor blue]
end

;; Create links between agents
to setup-links
  set-default-shape links "curvy"

  ask customers
  [ create-link-to one-of reps ]

  ask reps
  [ create-link-to one-of customers
    create-link-to one-of saps
    create-link-from one-of saps ]

  ask planners
  [ create-link-to one-of saps
    create-link-from one-of saps ]

  ask specialists
  [ create-link-from one-of saps
    create-link-to one-of carriers ]

  ask carriers
  [ create-link-to one-of saps
    create-link-to one-of dcenters ]

  ask plants
  [ create-link-to one-of planners ]

  ask saps
  [ create-link-to one-of plants ]

  ask links
  [ set color black ]
end


;; Main procedure that runs till all orders are completed
to go
  record-metrics
  check-night-time
  pass-info
  send-back-orders
  return-to-process
  lack-inventory
  end-simulation

  if end-simulation? = true [ stop ]

  tick
end

;; This is to end the simulation once all the orders have been processed
to end-simulation
  ;; Making sure all confirmation orders and invoice have been received by the customer
  let confirm-completed [completed?] of envelopes with [ typeof = "orderconfirmation" ]
  set confirm-completed remove-duplicates confirm-completed

  let invoice-completed [completed?] of envelopes with [ typeof = "invoice" ]
  set invoice-completed remove-duplicates invoice-completed


  ;; If all orders have been completed, end simulation
  if length confirm-completed = 1 and item 0 confirm-completed = true and
     length invoice-completed = 1 and item 0 invoice-completed = true
  [ set end-simulation? true ]

end

;; Records the average time to process a request per agent
to record-metrics
  ;; Average time to process orders for the people agents
  set rep-avg map [ ifelse-value (length [order-done] of ? > 0) [[waiting] of ? / length [order-done] of ?] [0]] sort reps
  set plan-avg map [ ifelse-value (length [order-done] of ? > 0) [[waiting] of ? / length [order-done] of ?] [0]] sort planners
  set spec-avg map [ ifelse-value (length [order-done] of ? > 0) [[waiting] of ? / length [order-done] of ?] [0]] sort specialists
  set carr-avg map [ ifelse-value (length [order-done] of ? > 0) [[waiting] of ? / length [order-done] of ?] [0]] sort carriers
  set plant-avg map [ ifelse-value (length [order-done] of ? > 0) [[waiting] of ? / length [order-done] of ?] [0]] sort plants

  ;; Total errors in the system
  set total-errors (rework-orders + correct-orders + return-orders)

  ;; Total orders completed
  set orders-completed (length filter [? = true] [completed?] of envelopes with [typeof = "orderconfirmation"])

  ;; Find the average time to complete each order
  if length [time-out] of envelopes with [typeof = "orderconfirmation" and time-out > 0] > 0
  [ set order-avg mean [time-out] of envelopes with [typeof = "orderconfirmation" and time-out > 0]

    if orders-completed > 0 [
      let timeouts [time-out] of envelopes with [typeof = "orderconfirmation" and time-out > 0]
      if length timeouts > 1 [ set st-dev standard-deviation timeouts ]

      set performance (length [time-out] of envelopes with [typeof = "orderconfirmation" and
                       time-out > 0 and time-out <= order-avg + st-dev]) / orders-completed
      set performance-nostd (length [time-out] of envelopes with [typeof = "orderconfirmation" and
                       time-out > 0 and time-out <= order-avg]) / orders-completed
    ]
  ]


end


;; Checks ticks to change background of interface
;; It will be used to make the people agents idle during night time
to check-night-time
  if ticks > 0 and ticks mod 12 = 0
  [ ask patches [set pcolor 102 ]
    set night-time? true
    ask night-day [
      set plabel "NIGHT TIME" ] ]

  if night-time? = true and night-hours > 0 [
  set night-hours (night-hours - ticks / ticks)]

  if night-hours = 0 and ticks mod 12 = 1
  [ ask patches with [ pycor < 0 ][ set pcolor green ]
    ask patches with [ pycor >= 0 ][ set pcolor blue ]
    set night-time? false
    set night-hours 12
    ask night-day [set plabel ""] ]
end

;; Transferring information throughout the process
;; @ select-order (Customer selects order and give it to Customer Rep.)
;; @ create-order (Customer rep. creates order in SAP)
;; @ planner-access (Planner gets accessed to order in SAP)
;; @ planner-complete (Planner completes tasks related to order)
;; @ planner-schedule (Planner sends order to Manufacturing plant)
;; @ plants-schedule (Plants completes task)
;; @ specialist-access (Transp. specialist gets accessed to order in SAP)
;; @ specialist-complete (Transp. specialist sends order to Carrier)
;; @ carrier-todistcenter (Carrier sends order to distribution center)
;; @ carrier-tosap (Carrier completes tasks)
;; @ sap-complete (SAP has a complete order, sends confirmation to rep)
;; @ rep-complete (Customer rep. sends confirmation to customer)
;; @ sap-tocustomer (SAP delivers invoice to customer)
to pass-info

  select-order "orderrequest" reps

  process-order reps saps "orderrequest" "ordercreation"
  transfer-order reps saps "ordercreation"

  process-order saps planners "ordercreation" "plannedorder"
  transfer-order saps planners "plannedorder"

  process-order planners saps "plannedorder" "productionorder"
  transfer-order planners saps "productionorder"

  process-order planners plants "plannedorder" "productionschedule"
  transfer-order planners plants "productionschedule"

  process-order plants saps "productionschedule" "ordercomplete"
  transfer-order plants saps "ordercomplete"

  process-order saps specialists "ordercreation" "createdelivery"
  transfer-order saps specialists "createdelivery"

  process-order specialists carriers "createdelivery" "arrangetransp"
  transfer-order specialists carriers "arrangetransp"

  process-order carriers saps "arrangetransp" "deliverynotice"
  transfer-order carriers saps "deliverynotice"

  process-order carriers dcenters "arrangetransp" "distcenter"
  transfer-order carriers dcenters "distcenter"

  process-order saps customers "deliverynotice" "invoice"
  transfer-order saps customers "invoice"

  process-order saps reps "productionorder" "availability"
  transfer-order saps reps "availability"

  process-order reps customers "availability" "orderconfirmation"
  transfer-order reps customers "orderconfirmation"

end

;; Customer selects order and gives it to Customer Rep.
;; @ typep: type of information agent
;; @ dest: agent receiving information
to select-order [ typep dest ]
  let reps-queues [length queue] of dest
  let reps-capacities [queue-capacity] of dest

  ;; Checking that the customer has orders to submit
  ;; and reps have capacity to take orders
  if length list_orders > 0 and ticks mod 10 = 0
  ;; Selecting random order from list
  [ let myindex (item random (length list_orders) list_orders)
    ;; Setting move? to true to allow this agent to move
    ask envelopes with [typeof = typep and index-order = myindex]
    ;; Sending orders to agents with the expertise to process the order
    [ if [efficiency] of one-of dest >= expertise-required
      [ set move? true ]
    ]
    ;; Removing value from list as it was already selected
    set list_orders remove myindex list_orders
  ]

  ;; Calling all the selected orders to move
  ask envelopes with [typeof = typep and move? = true]
  [ ifelse color = white
    [ face min-one-of dest [length queue] move-slow ]
    [ face min-one-of dest [length queue] move ]

    add-order who dest
  ]
end

;; Adds task to the queue of dest agent
;; @ envnumber: envelope number -- who
;; @ dest: agent to receive information
to add-order [ envnumber dest ]
  let myindexorder [index-order] of envelope envnumber
  let agent-select ""

  ifelse prioritize-type = "Availability"
  ;; Find agent with minimum orders in queue
  [ set agent-select [who] of min-one-of dest [length queue] ]

  ;; Find agent with highest efficiency
  [ set agent-select [who] of max-one-of dest [efficiency] ]

  ;; Obtaining the expertise required to process the order
  let expertise-needed [expertise-required] of envelope envnumber

  ;; Asks the agent with the least number of tasks in their queue
  ask dest with [length queue < queue-capacity and efficiency >= expertise-required
    and who = agent-select ]; and who = agent-min-queue
    [ let d distance myself
      if d < 0.5
      [ if (any? dest with [member? (myindexorder + 1) order-done] = false and
        any? dest with [member? (myindexorder + 1) queue] = false)
        [ set queue lput (myindexorder + 1) queue

          ;; This is to calculate the waiting time in the queue
          if [waiting] of envelope envnumber = 0
          [ ask envelope envnumber [ set waiting ticks ] ]

          ;; This is to obtain the time at which the order was added into the process
          if [time-in] of envelope envnumber = 0
          [ ask envelopes with [index-order = myindexorder] [ set time-in ticks ] ]

          set queue remove-duplicates queue
        ]
      ]
    ]
end


;; Processing the order in queue
;; @ from: agent with orders in queue
;; @ dest: agent to receive order
;; @ typep: type of information agent to be processed
;; @ typeto: type of information agent to be activated
to process-order [ from dest typep typeto ]
  if member? typeto exception-procedures = false
  [ foreach [queue] of from [
    if length ? > 0 [
      ;; Select order in queue
      select-process-type from ? typep
      ;; Ask the corresponding order in the queue
      ask envelopes with [ typeof = typep and index-order = process-variable - 1 ]
      [ set hidden? false
        set move? true
        ;; Applying the efficiency of the agent
        if apply-efficiency? = false
        [ let agent from with [ member? process-variable queue = true ]
          ;; Checking if the agent has processed enough orders to increase its efficiency
          increase-efficiency agent length item 0 [order-done] of agent
          set processing-time (processing-time / item 0 [efficiency] of agent)
          set apply-efficiency? true
        ]
        ;; Process the order based on its size
        ifelse processing-time > 0
        [ ifelse typeto != "distcenter"
          [ ;check-incompleteness from who
            set processing-time (processing-time - ticks / ticks) ]
          ;; This is to avoid inventory to go below 0
          [ ifelse dist-amount > 0
            [ set processing-time (processing-time - ticks / ticks)
              set dist-amount (dist-amount - ticks / ticks) ]
            [ lack-inventory ]
          ]
        ]
        ;; If order is incomplete, handle exception.
        ;; Otherwise remove order from queue
        [ ifelse incompleteness >= (100 - error-percent)
          [ handle-incompleteness from typep index-order ]
          [ remove-order dest from who typep typeto ]
        ]
      ]
    ]
  ]
]
end

;; Selects the order in agent's queue that will be processed based on
;; processing-type or existence of rush orders
;; @ agent: agent to process order
;; @ agent-queue: queue of agent
;; @ info-type: type of information agent
to select-process-type [ agent agent-queue info-type]
  ;; Verifies if agent has a rush order in queue
  let contains-rush-order map [ ifelse-value (item 0 [urgency] of envelopes
      with [typeof = info-type and index-order = ? - 1] >= 90) [true] [false] ] agent-queue

  ;; If rush order is in the queue, it needs to be processed
  ifelse member? true contains-rush-order
  [ let position-rush-order position true map [ item 0 [urgency] of envelopes
        with [typeof = info-type and index-order = ? - 1] >= 90 ] agent-queue
    set process-variable item position-rush-order agent-queue
  ]

  ;; Select the processing-type of the agent when no rush orders in its queue
  [ if item 0 [processing-type] of agent = "FIFO" [ set process-variable first agent-queue ]
    if item 0 [processing-type] of agent = "LIFO" [ set process-variable last agent-queue ]
    if item 0 [processing-type] of agent = "Rapid Response" [ rapid-response agent-queue info-type ]
    if item 0 [processing-type] of agent = "Complicated" [ complicated-response agent-queue info-type ]
  ]
end

;; handle-incompleteness: randomly selects how to handle the incomplete order
;; @ from: agent with the order
;; @ typep: type of order
;; @ indexorder: order's incompleteness to be checked
to handle-incompleteness [ from typep indexorder ]
  ask envelopes with [typeof = typep and index-order = indexorder]
  [ set color black
    ;; Selects randomly the type of error
    let handle-option one-of incomplete-options

    ;; rework: process entire order again
    if handle-option = "rework" [
      set processing-time init-process-time / item 0 [efficiency] of from with
      [member? process-variable queue = true]
      set rework-orders (rework-orders + 1)
    ]

    ;; correct: corrects half of the volume of the order
    if handle-option = "correct" [
      set processing-time (init-process-time / 2) / item 0 [efficiency] of from with
      [member? process-variable queue = true]
      set correct-orders (correct-orders + 1)
    ]

    ;; send-back: returns order to one of the agents that has made an error on the order
    if handle-option = "send-back" [
      ;; Removes order from agent's queue
      let returnfrom ""
      ask from with [member? process-variable queue = true] [
        set queue remove process-variable queue
        set returnfrom label
      ]
      set return-order? true
      set return-to item 0 one-of signatures
      set return-orders (return-orders + 1)
      set return-from returnfrom
    ]

    ;; Reduces the incompleteness of the order
    ask envelopes with [index-order = indexorder]
    [ set incompleteness (incompleteness - random 50) ]
  ]

end

;; send-back-orders: sends the order back to one of the agents that has
;; processed the order
to send-back-orders
  ask envelopes with [return-order? = true and typeof != ""]
  [ let returnto return-to
    let indexorder index-order
    let who-is who

    if member? returnto label-customers
    [ return-to-previous who-is customers returnto ]

    if member? returnto label-reps
    [ return-to-previous who-is reps returnto ]

    if member? returnto label-saps
    [ return-to-previous who-is saps returnto ]

    if member? returnto label-planners
    [ return-to-previous who-is planners returnto ]

    if member? returnto label-plants
    [ return-to-previous who-is plants returnto ]

    if member? returnto label-specs
    [ return-to-previous who-is specialists returnto ]

    if member? returnto label-carriers
    [ return-to-previous who-is carriers returnto ]
  ]
end

;; return-to-previous: returns the order to an agent that has already
;; processed the order
;; @ envnumber: order number
;; @ agent-to: agent who will rework order
;; @ return-label: label of agent
to return-to-previous [ envnumber agent-to return-label]
  ask envelopes with [ who = envnumber ]
  [ set color green
    set typeof "return-order"

    face one-of agent-to with [label = return-label] move

    ask one-of agent-to [
      let d distance myself
      if d < 0.5 [
        ask envelopes with [who = envnumber]
        [ set typeof "" ]
      ]
    ]
  ]
end

;; return-to-process: Returns order to the last agent that worked on the order
to return-to-process
  ask envelopes with [typeof = ""]
  [ let returnfrom return-from
    let indexorder index-order
    let who-is who
    face one-of turtles with [label = returnfrom] move
    ask one-of turtles with [label = returnfrom]
    [ let d distance myself
      if d < 0.5 [
        set queue lput (indexorder + 1) queue
        ask envelopes with [who = who-is] [
          set typeof type-init
          set return-order? false
        ]
      ]
    ]
  ]
end

;; Rapid response: selects the smallest order in the queue of an agent
;; @ agent-queue: queue
;; @ agent-type: type of agent
to rapid-response [ agent-queue agent-type ]
  ;; Finding the processing times of all orders in queue
  let min-list (map [item 0 [init-process-time] of envelopes
      with [typeof = agent-type and index-order = ? - 1]] agent-queue)
  ;; Finding position of smallest order in queue
  let min-value-pos position min min-list min-list
  set process-variable item min-value-pos agent-queue
end

;; Complicated response: selects the largest order in the queue of an agent
;; @ agent-queue: queue
;; @ agent-type: type of agent
to complicated-response [ agent-queue agent-type ]
  ;; Finding the processing times of all orders in queue
  let time-list (map [item 0 [init-process-time] of envelopes
      with [typeof = agent-type and index-order = ? - 1]] agent-queue)
  ;; Finding position of largest order in queue
  let max-value-pos position max time-list time-list
  set process-variable item max-value-pos agent-queue
end

;; Removes task from the queue of the askto agent
;; @ faceto: envelope will go to this agent
;; @ askto: agent's queue to be updated
;; @ envnumber: number of envelope to be called
to remove-order [ faceto askto envnumber typep typeto ]

  ask envelopes with [ typeof = typeto and move? = true ]
  [ ifelse [ color ] of envelopes = white
   [ face (min-one-of faceto [length queue]) move-slow ]
   [ face (min-one-of faceto [length queue]) move ] ]

  ;; Ask the agent that contains the task to remove task from queue
  ask askto with [ member? (([index-order] of envelope envnumber) + 1) queue ][
    set waiting (waiting + (ticks - [waiting] of envelope envnumber))
    set queue remove (([index-order] of envelope envnumber) + 1) queue
    set order-done lput (([index-order] of envelope envnumber) + 1) order-done
    set lastorder-time (ticks - [waiting] of envelope (envnumber))

    ;; Including the label of the agent who processed the order
    let agent-label label
    let indexorder [index-order] of envelope envnumber
    ask envelopes with [index-order = indexorder]
    [ set signatures lput [label] of askto with [label = agent-label] signatures ]

    ;; If information agent has been completed, ask it to die
    ask envelope envnumber [ die ]
  ]
end

;; Transfers orders in agents order-done list to the queue
;; of the next agent responsible for processing the task
;; @ from: agent with orders completed
;; @ dest: agent to be assigned the order
;; @ typep: the type of information agent
to transfer-order [ from dest typep ]
  ifelse member? typep exception-procedures = false
  [ foreach [order-done] of from
    [ if length ? > 0
      [ let orderdone ?
        foreach orderdone
        ;; Asks the corresponding envelope to move to its final destination
        [ ask envelopes with [ typeof = typep and index-order = ? - 1 ]
          [ ifelse (color = red and typep = "plannedorder")
            [ ]
            [ set hidden? false
              ifelse color = white
              [ face min-one-of dest [length queue] move-slow ]
              [ face min-one-of dest [length queue] move ]
              set completed? true
              add-order who dest
            ]
          ]
        ]
      ]
    ]
  ]
  [ send-invoice dest typep ]
end

;; Send invoice to Cust. rep and Customer
;; @ dest: agent to receive the confirmation agent
;; @ typep: type of confirmation
to send-invoice [ dest typep ]
  if length [ order-done ] of one-of saps > 0
  [ let completed-list [ order-done ] of one-of saps
    foreach completed-list
    [ ask envelopes with [ typeof = typep and index-order = ? - 1 ]
     [ let pta item 0 [xcor] of envelopes with [ typeof = "productionorder" and index-order = ? - 1 ]
        let ptb item 0 [xcor] of envelopes with [ typeof = "deliverynotice" and index-order = ? - 1 ]
        let ptc item 0 [xcor] of envelopes with [ typeof = "ordercomplete" and index-order = ? - 1  ]

        ifelse color = white
        [ if pta < 0.5 and pta > -0.5 and ptb < 0.5 and ptb > -0.5 and ptc < 0.5 and ptc > -0.5
          [ set hidden? false
            set move? true ]
        ]

        [ if ptb < 0.5 and ptb > -0.5
          [ set hidden? false
            set move? true ]
        ]
      ]
    ]
  ]

  if typep = "orderconfirmation"
  [ ask envelopes with [ typeof = typep  and
          index-order = [index-order] of envelopes with [ typeof = "availability" and ycor > 9.5 ] ]
      [ set hidden? false
        face one-of dest move-slow
        set completed? true ]
  ]

  ask envelopes with [ typeof = typep and move? = true ]
  [ face one-of dest move-slow
    if xcor > 9.5 = true
    [ if time-out = 0 [ set time-out (ticks - time-in) ]
      set completed? true ]
    ]

end

;; This is to send inventory constantly
to lack-inventory
  if dist-amount < 800 [
  if ticks > small-inventory
  [  ask one-of trucks with [completed? = false] with-min [index-order]
    [ set hidden? false
      set amount-material 100 ]
    set small-inventory (small-inventory + 550) ]

  if ticks > large-inventory
  [  ask one-of trucks with [completed? = false] with-min [index-order]
    [ set hidden? false
      set amount-material 500 ]
    set large-inventory (large-inventory + 500) ]
  ]

  ask trucks with [completed? = false and hidden? = false] [
    face one-of dcenters (fd 1)
    let d distance one-of dcenters
    if d < 0.5 [
      set dist-amount (dist-amount + amount-material)
      set completed? true
      set index-order (index-order + make-to-order)
    ]
  ]
end

;; This is to increase the efficiency of the agent
;; @agent: agent's efficiency to be increased
;; @order-done-length: length of orders completed
to increase-efficiency [ agent order-done-length ]
  let efficiency-increase item 0 [learning-steps] of agent
  let efficiency-agent item 0 [efficiency] of agent

  if item 0 efficiency-increase = false and order-done-length >= 10 and order-done-length < 20
  and efficiency-agent < 0.65
  [ ask agent
    [ set efficiency (efficiency + 0.2)
      set learning-steps replace-item 0 learning-steps true
      if efficiency > 1 [ set efficiency 1 ] ]
    ]

  if item 1 efficiency-increase = false and order-done-length >= 30 and order-done-length < 40
  and efficiency-agent < 0.85
  [ ask agent
    [ set efficiency (efficiency + 0.1)
      set learning-steps replace-item 1 learning-steps true
      if efficiency > 1 [ set efficiency 1 ] ]
    ]

  if item 2 efficiency-increase = false and order-done-length >= 60
  ;;and (efficiency-agent <= 0.85
  [ ask agent
    [ set efficiency (efficiency + 0.05)
      set learning-steps replace-item 2 learning-steps true
      if efficiency > 1 [ set efficiency 1 ] ]
    ]
  setup-queues
end

;; Sets speed at which make-to-stock orders move
to move
  fd 0.5
end

;; Sets speed at which make-to-order orders move
to move-slow
  fd 0.3
end
@#$#@#$#@
GRAPHICS-WINDOW
165
30
604
490
16
16
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
15
30
78
63
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
80
30
140
63
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
235
150
268
make-to-order
make-to-order
0
100
100
10
1
NIL
HORIZONTAL

SLIDER
15
280
150
313
make-to-stock
make-to-stock
0
100
0
10
1
NIL
HORIZONTAL

PLOT
610
185
870
335
Avg. Time of Reps
Time [ticks]
Avg. time
0.0
10.0
5.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask reps [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    if length order-done > 0\n    [ plotxy ticks (waiting / length order-done) ]\n  ]\n]"
PENS

PLOT
610
495
870
645
Avg. Time of Specialists
Time [ticks]
Avg. time
0.0
10.0
10.0
15.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask specialists [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    if length order-done > 0\n    [ plotxy ticks (waiting / length order-done) ]\n  ]\n]"
PENS

PLOT
610
650
870
800
Avg. Time of Carriers
Time [ticks]
Avg. time
0.0
10.0
5.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask carriers [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    if length order-done > 0\n    [ plotxy ticks (waiting / length order-done) ]\n  ]\n]"
PENS

PLOT
610
30
870
180
Avg. Time of Plants
Time [ticks]
Avg. time
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green]\n  ask plants [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    if length order-done > 0\n    [ plotxy ticks (waiting / length order-done) ]\n  ]\n]"
PENS

SLIDER
15
320
145
353
dist-amount
dist-amount
200
200
200
10
1
NIL
HORIZONTAL

MONITOR
1610
185
1722
230
Current Inventory
dist-amount
3
1
11

SLIDER
15
115
145
148
planner-total
planner-total
1
5
3
1
1
NIL
HORIZONTAL

SLIDER
15
155
145
188
spec-total
spec-total
1
5
2
1
1
NIL
HORIZONTAL

SLIDER
15
190
145
223
carrier-total
carrier-total
1
5
1
1
1
NIL
HORIZONTAL

PLOT
875
650
1135
800
Carrier's Queue
Time [ticks]
# orders in queue
0.0
10.0
0.0
1.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\nask carriers [\n  create-temporary-plot-pen (label)\n  set-plot-pen-color item index-order color-list\n  plotxy ticks length queue\n] ]"
PENS

PLOT
875
185
1135
335
Reps' Queue
Time [ticks]
# orders in queue
0.0
10.0
0.0
1.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask reps [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    plotxy ticks length queue \n  ]\n]"
PENS

PLOT
875
340
1135
490
Planner's Queue
Time [ticks]
# orders in queue
0.0
10.0
0.0
1.0
true
true
"" "if plots-on? = true [\nlet color-list [ blue red green ]\n  ask planners [\n    create-temporary-plot-pen label\n    set-plot-pen-color item index-order color-list\n    plotxy ticks length queue\n  ]\n]"
PENS

PLOT
875
495
1135
645
Specialist's Queue
Time [ticks]
# orders in queue
0.0
10.0
0.0
1.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\nask specialists [\n  create-temporary-plot-pen (label)\n  set-plot-pen-color item index-order color-list\n  plotxy ticks length queue\n] ]"
PENS

PLOT
875
30
1135
180
Plant's Queue
Time [ticks]
# orders in queue
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [ \n  ask plants [\n    create-temporary-plot-pen (\"Plant\")\n    set-plot-pen-color black\n    plotxy ticks length queue\n    ]\n  ]"
PENS

PLOT
1400
30
1660
180
Inventory
Time [ticks]
Inventory
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [ \n  create-temporary-plot-pen \"Inventory\"\n  set-plot-pen-color black\n  plotxy ticks dist-amount ]"
PENS

SLIDER
15
75
145
108
rep-total
rep-total
1
5
1
1
1
NIL
HORIZONTAL

MONITOR
1825
390
1900
435
completed
orders-completed
17
1
11

SWITCH
15
365
117
398
plots-on?
plots-on?
0
1
-1000

CHOOSER
15
525
145
570
processing-type-reps
processing-type-reps
"FIFO" "LIFO" "Rapid Response" "Complicated"
0

CHOOSER
155
525
285
570
processing-type-specs
processing-type-specs
"FIFO" "LIFO" "Rapid Response" "Complicated"
3

CHOOSER
155
575
285
620
processing-type-carriers
processing-type-carriers
"FIFO" "LIFO" "Rapid Response" "Complicated"
0

CHOOSER
15
625
145
670
processing-type-plan
processing-type-plan
"FIFO" "LIFO" "Rapid Response" "Complicated"
0

CHOOSER
15
575
145
620
processing-type-plant
processing-type-plant
"FIFO" "LIFO" "Rapid Response" "Complicated"
0

SLIDER
310
530
450
563
rep-efficiency
rep-efficiency
40
90
40
1
1
%
HORIZONTAL

SLIDER
310
600
450
633
planner-efficiency
planner-efficiency
40
90
90
1
1
%
HORIZONTAL

SLIDER
460
530
600
563
spec-efficiency
spec-efficiency
40
90
90
1
1
%
HORIZONTAL

SLIDER
460
565
600
598
carrier-efficiency
carrier-efficiency
40
90
90
1
1
%
HORIZONTAL

SLIDER
310
565
450
598
plant-efficiency
plant-efficiency
40
100
89
1
1
%
HORIZONTAL

TEXTBOX
315
510
405
528
Set Efficiencies
11
0.0
1

TEXTBOX
20
505
150
523
Set Processing Types
11
0.0
1

PLOT
1410
185
1605
335
Reps' Efficiencies
NIL
NIL
0.0
10.0
40.0
100.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask reps [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    plotxy ticks efficiency * 100\n  ]\n]"
PENS

PLOT
1405
340
1605
490
Planners' Efficiencies
NIL
NIL
0.0
10.0
40.0
100.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green]\n  ask planners [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    plotxy ticks efficiency * 100 \n  ]\n]"
PENS

PLOT
1405
495
1605
645
Specs' Efficiencies
NIL
NIL
0.0
10.0
40.0
100.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\nask specialists [\n  create-temporary-plot-pen (label)\n  set-plot-pen-color item index-order color-list\n  plotxy ticks efficiency * 100\n] ]"
PENS

PLOT
1405
660
1605
810
Carriers' Efficiencies
NIL
NIL
0.0
10.0
40.0
100.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\nask carriers [\n  create-temporary-plot-pen (label)\n  set-plot-pen-color item index-order color-list\n  plotxy ticks efficiency * 100\n] ]"
PENS

PLOT
1140
185
1395
335
Reps' completed
Time [ticks]
Orders completed
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask reps [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    plotxy ticks length order-done \n  ]\n]"
PENS

PLOT
1140
340
1395
490
Planners' completed
Time [ticks]
Orders completed
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask planners [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    plotxy ticks (length order-done) \n  ]\n]"
PENS

PLOT
1140
495
1395
645
Specialists' completed
Time [ticks]
Orders completed
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\nask specialists [\n  create-temporary-plot-pen (label)\n  set-plot-pen-color item index-order color-list\n  plotxy ticks length order-done\n] ]"
PENS

PLOT
1140
650
1395
800
Carriers' completed
Time [ticks]
Orders completed
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\nask carriers [\n  create-temporary-plot-pen (label)\n  set-plot-pen-color item index-order color-list\n  plotxy ticks length order-done\n] ]"
PENS

PLOT
1140
30
1395
180
Plant's completed
Time [ticks]
Orders completed
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [ \n  ask plants [\n    create-temporary-plot-pen (\"Plant\")\n    set-plot-pen-color black\n    plotxy ticks length order-done \n    ]\n  ]"
PENS

MONITOR
1610
390
1700
435
Reworked orders
rework-orders
17
1
11

MONITOR
1610
435
1700
480
Corrected orders
correct-orders
17
1
11

PLOT
610
340
870
490
Avg. Time of Planners
Time [ticks]
Avg. time
0.0
10.0
0.0
10.0
true
true
"" "if plots-on? = true [\nlet color-list [blue red green brown orange]\n  ask planners [\n    create-temporary-plot-pen (label)\n    set-plot-pen-color item index-order color-list\n    if length order-done > 0\n    [ plotxy ticks (waiting / length order-done) ]\n  ]\n]"
PENS

MONITOR
1610
480
1700
525
Returned orders
return-orders
17
1
11

PLOT
1610
235
1850
385
Errors
Time [ticks]
Error
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"rework" 1.0 0 -13345367 true "" "plot rework-orders"
"correct" 1.0 0 -2674135 true "" "plot correct-orders"
"return" 1.0 0 -10899396 true "" "plot return-orders"

MONITOR
1705
390
1782
435
Total errors
total-errors
17
1
11

TEXTBOX
315
645
500
671
Mishandlings/ Errors made by agents
11
0.0
1

MONITOR
1825
435
1892
480
NIL
order-avg
17
1
11

CHOOSER
15
420
145
465
prioritize-type
prioritize-type
"Expertise" "Availability"
1

SLIDER
315
660
455
693
error-percent
error-percent
0
30
10
10
1
%
HORIZONTAL

MONITOR
1725
435
1807
480
NIL
performance
17
1
11

MONITOR
1825
480
1890
525
st.deviation
st-dev
17
1
11

MONITOR
1705
485
1822
530
NIL
performance-nostd
17
1
11

@#$#@#$#@
## Agent-based Modeling and Simulation for an Order-To-Cash Process
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

@article{villarraga2017agent,
  title={Agent-based Modeling and Simulation for an Order-To-Cash Process using NetLogo},
  author={Villarraga, John and Carley, Kathleen M and Wassick, John and Sahinidis, Nikolaos},
  year={2017}
}



@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

computer workstation
false
0
Rectangle -7500403 true true 60 45 240 180
Polygon -7500403 true true 90 180 105 195 135 195 135 210 165 210 165 195 195 195 210 180
Rectangle -16777216 true false 75 60 225 165
Rectangle -7500403 true true 45 210 255 255
Rectangle -10899396 true false 249 223 237 217
Line -16777216 false 60 225 120 225

container
false
0
Rectangle -7500403 false false 0 75 300 225
Rectangle -7500403 true true 0 75 300 225
Line -16777216 false 0 210 300 210
Line -16777216 false 0 90 300 90
Line -16777216 false 150 90 150 210
Line -16777216 false 120 90 120 210
Line -16777216 false 90 90 90 210
Line -16777216 false 240 90 240 210
Line -16777216 false 270 90 270 210
Line -16777216 false 30 90 30 210
Line -16777216 false 60 90 60 210
Line -16777216 false 210 90 210 210
Line -16777216 false 180 90 180 210

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

letter opened
false
0
Rectangle -7500403 true true 30 90 270 225
Rectangle -16777216 false false 30 90 270 225
Line -16777216 false 150 30 270 105
Line -16777216 false 30 105 150 30
Line -16777216 false 270 225 181 161
Line -16777216 false 30 225 119 161
Polygon -6459832 true false 30 105 150 30 270 105 150 180
Line -16777216 false 30 105 270 105
Line -16777216 false 270 105 150 180
Line -16777216 false 30 105 150 180

letter sealed
false
0
Rectangle -7500403 true true 30 90 270 225
Rectangle -16777216 false false 30 90 270 225
Line -16777216 false 270 105 150 180
Line -16777216 false 30 105 150 180
Line -16777216 false 270 225 181 161
Line -16777216 false 30 225 119 161

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

tank
true
0
Rectangle -7500403 true true 144 0 159 105
Rectangle -6459832 true false 195 45 255 255
Rectangle -16777216 false false 195 45 255 255
Rectangle -6459832 true false 45 45 105 255
Rectangle -16777216 false false 45 45 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -7500403 true true 90 60 60 90 60 240 120 255 180 255 240 240 240 90 210 60
Rectangle -16777216 false false 135 105 165 120
Polygon -16777216 false false 135 120 105 135 101 181 120 225 149 234 180 225 199 182 195 135 165 120
Polygon -16777216 false false 240 90 210 60 211 246 240 240
Polygon -16777216 false false 60 90 90 60 89 246 60 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 237 89 236
Rectangle -16777216 false false 90 60 210 90
Rectangle -16777216 false false 143 0 158 105

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

train freight hopper empty
false
0
Circle -16777216 true false 253 195 30
Circle -16777216 true false 220 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 17 195 30
Rectangle -16777216 true false 105 90 135 90
Rectangle -16777216 true false 285 180 294 195
Polygon -7500403 true true 15 105 15 120 45 180 45 195 255 195 255 180 285 120 285 105
Rectangle -7500403 false true 15 105 285 195
Rectangle -16777216 true false 6 180 15 195
Polygon -7500403 true true 90 195 105 210 120 195
Polygon -7500403 true true 135 195 150 210 165 195
Polygon -7500403 true true 180 195 195 210 210 195
Polygon -16777216 false false 15 105 15 120 45 180 45 195 255 195 255 180 285 120 285 105
Line -16777216 false 60 105 60 195
Line -16777216 false 240 105 240 195
Line -16777216 false 180 105 180 195
Line -16777216 false 120 105 120 195

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="maketoorder" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="initialinventory" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="dist-amount" first="0" step="100" last="1000"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketostock" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-stock" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-order">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_reps" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rep-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_carriers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="carrier-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_specs" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="spec-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketoorder_lifo" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="initialinventory_lifo" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="dist-amount" first="0" step="100" last="1000"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketostock_lifo" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-stock" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-order">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_reps_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rep-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_carriers_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="carrier-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_specs_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="spec-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_reps_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rep-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_carriers_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="carrier-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multiple_specs_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="spec-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incomplete-orders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketoorder_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketostock_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-stock" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-order">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="initialinventory_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="dist-amount" first="0" step="100" last="1000"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketoorder_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketostock_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-stock" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="make-to-order">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="initialinventory_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <steppedValueSet variable="dist-amount" first="0" step="100" last="1000"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="maketoorder_200" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>dist-amount</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_demand200" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_reps_a" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <steppedValueSet variable="rep-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_demand300" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="210" step="10" last="300"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_reps_e" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <steppedValueSet variable="rep-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Expertise&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_training100" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_training95" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_training" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rep-efficiency" first="95" step="5" last="100"/>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_specs_a" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="spec-total" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_optimal" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <steppedValueSet variable="rep-total" first="2" step="1" last="5"/>
    <steppedValueSet variable="planner-total" first="2" step="1" last="5"/>
    <steppedValueSet variable="spec-total" first="2" step="1" last="5"/>
    <steppedValueSet variable="carrier-total" first="2" step="1" last="5"/>
    <enumeratedValueSet variable="make-to-order">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_carrs_a" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-order">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-to-stock">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_type_fifo" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="50" step="50" last="250"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;FIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_type_lifo" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="50" step="50" last="250"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;LIFO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_type_rr" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="50" step="50" last="250"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;Rapid Response&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="paper_type_c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>rep-avg</metric>
    <metric>spec-avg</metric>
    <metric>plan-avg</metric>
    <metric>carr-avg</metric>
    <metric>plant-avg</metric>
    <metric>rework-orders</metric>
    <metric>return-orders</metric>
    <metric>correct-orders</metric>
    <metric>total-errors</metric>
    <metric>orders-completed</metric>
    <metric>order-avg</metric>
    <metric>st-dev</metric>
    <metric>performance</metric>
    <metric>performance-nostd</metric>
    <enumeratedValueSet variable="rep-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-total">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-total">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-total">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="make-to-order" first="50" step="50" last="250"/>
    <enumeratedValueSet variable="make-to-stock">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-amount">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-reps">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plant">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-plan">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-specs">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="processing-type-carriers">
      <value value="&quot;Complicated&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rep-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plant-efficiency">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="planner-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spec-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrier-efficiency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prioritize-type">
      <value value="&quot;Availability&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
14
Line -7500403 false 150 150 90 180
Line -7500403 false 150 150 210 180

ctwo
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 1 1.0 0.0
link direction
true
14
Line -7500403 false 150 150 90 180
Line -7500403 false 150 150 210 180

curvy
2.0
-0.2 1 4.0 4.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
14
Line -7500403 false 150 150 90 180
Line -7500403 false 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
