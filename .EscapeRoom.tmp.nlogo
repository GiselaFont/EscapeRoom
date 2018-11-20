breed [dangers danger]
breed [people person]

dangers-own [
  radius
]

people-own [
  age
  ;; position xcor, ycor
  ;; heading
  speed
  vision-radius
  ;; distance-to-danger
  energy-level
  ;; belief-of-movement
]

extensions [table]

globals [
  num-angles
  pop-size
  danger-growth-coeff
]

to normalize-pop
  let total (frac-young + frac-average + frac-old)
  set frac-young round (100 * frac-young / total)
  set frac-average round (100 * frac-average / total)
  set frac-old 100 - (frac-young + frac-average)
end

;;Button setup
to setup
  clear-all

  set num-angles 8
  set pop-size 100
  set danger-growth-coeff 0.01

  ;;set vision-radius 10

  setup-patches
  setup-people
  setup-many-dangers number-of-dangers
  reset-ticks
end

;;Environment setup
to setup-patches
  ask patches [ set pcolor white ]
end

to setup-people
  set-default-shape people "person"

  normalize-pop

  create-people number-of-people * frac-young / 100 [
    set age 0
    set speed 0
    set vision-radius 4
    set energy-level 10
    set color green
  ]

  create-people number-of-people * frac-average / 100 [
    set age 1
    set speed 0
    set vision-radius 4
    set energy-level 10
    set color orange
  ]

  create-people number-of-people * frac-old / 100 [
    set age 2
    set speed 0
    set vision-radius 4
    set energy-level 10
    set color blue
  ]

  ask people [
    setxy random-xcor random-ycor
    set heading (random 360)
  ]
end


to setup-many-dangers [ n ]
  create-dangers n [
    set xcor random-xcor
    set ycor random-ycor
    set radius 1
    set color black
    set size (2 * radius)
    set shape "circle"
  ]
end

;;------------------------


to go
  show (word "in go 1")
  if ticks >= 1000 [ stop ]
  move-people
  check-death
  grow-dangers
  tick
end


to move-people
  ask people [

    ;; get dangers within radius r of x,y
    let x xcor
    let y ycor
    let vision-r vision-radius
    let visible-dangers (dangers with [in-danger-radius x y vision-r])
    ;let visible-dangers (dangers in-radius vision-radius)

    ifelse (count visible-dangers >= 1) [
      show "I see danger!!"
      show who
      ;; I can see one or more danger
      let chosen-danger (one-of visible-dangers)
      let x2 [xcor] of chosen-danger
      let y2 [ycor] of chosen-danger
      let dir-to-danger (get-directions xcor ycor x2 y2)
      show (word "direction to danger=" dir-to-danger)
      let opp-dir ((dir-to-danger + (num-angles / 2)) mod num-angles)
      show (word "opposite direction=" opp-dir "heading=" heading)
      face-direction opp-dir
      set speed 1.0 ;; to do... calc speed
    ]
    [
      ;; I see no danger, try and imitate the people I see

      let dir-stats (get-movement-stats xcor ycor vision-radius)
      ifelse (length dir-stats > 0) [
        ;; I see someone moving nearby
        let max-values-list-length length dir-stats ;get the length of the list to select a random item from the list
        show (word "length !!!!! = " max-values-list-length)
        let new-dir (item (random max-values-list-length) dir-stats)
        ;let new-dir (item 0 dir-stats)   ;; we pick the first person and imitate them... to do make this real
        face-direction new-dir
        set speed 1.0 ;; to do... calc speed
      ]
      [
        ;; I see no one moving continue unchanged heading and speed
      ]
    ]

    forward (speed)

    let energy-used 0 ;; to do

    set energy-level (energy-level - energy-used)
  ]
end


to grow-dangers
  ask dangers [
    let calc-radius (exp (danger-growth-coeff * ticks))
    set radius calc-radius
    ;show (word "radius = " calc-radius)
    set size (2 * calc-radius)
  ]
end


to check-death

  ;; death by danger
  ask dangers [
    let will-die (people in-radius radius)
    ask will-die [
      die
    ]
  ]

  ;; death by energy-level
  ask people [
    if energy-level <= 0 [
      die
    ]
  ]
end



;Returns the degree that the agent should face
to face-direction [direction]
  ;;let actionToDirectionAngle set-get-directions-table
  ;;report table:get actionToDirectionAngle direction

  set heading (direction * 360 / num-angles)
end

to-report in-danger-radius [x y vision-r]
  let d2 sqrt((x - xcor) * (x - xcor) + (y - ycor) * (y - ycor));calculate distance to the danger
  let ans (d2 <= (vision-r + radius)) ;returns true if the person sees the danger within their vision-radius
  report ans
end

to-report in-ball [x y r]
  let d2 ((xcor - x) * (xcor - x) + (ycor - y) * (ycor - y))
  let ans (d2 < (r * r))
  report ans
end

to-report get-movement-stats [x y r]

  ;; get turtles in ball of radius r of x,y
  let ball (turtles with [in-ball x y r])

  let list-of-directions []
  ask ball [
    let my-disc-heading (get-discrete-heading heading)                ;; compute my discrete heading
    set list-of-directions (lput my-disc-heading list-of-directions)  ;; append my discrete heading to list
  ]

  let list-of-keys-with-max-values-in-table []
  let list-of-directions-to-number-of-occurrences table:make
  if (length list-of-directions > 0) [
    foreach list-of-directions [
      [dir] -> show (word "direction=" dir)
      ifelse ((table:has-key? list-of-directions-to-number-of-occurrences dir) = false)[
        table:put list-of-directions-to-number-of-occurrences dir 0
      ]
      [
        let dir-count table:get list-of-directions-to-number-of-occurrences dir + 1
        table:put list-of-directions-to-number-of-occurrences dir dir-count
        show (word "Directions count=" dir-count)
      ]
    ]
    set list-of-keys-with-max-values-in-table get-max-values-in-table list-of-directions-to-number-of-occurrences
    show (word "************************" list-of-keys-with-max-values-in-table)
    ;show list-of-directions-to-number-of-occurrences
  ]

  ;; either empty list, or a list with one winner (currently just randomly chosen)
  report list-of-keys-with-max-values-in-table
end

;;!!!!!!For testing ONLY!!!!!!!
to-report get-table
  let new-table table:make
  table:put new-table 0 1
  table:put new-table 1 1
  report new-table
end
;---------------------------

;returns a list with the keys with the highest values from the table
to-report get-max-values-in-table [mtable]
  let list-of-values table:values mtable
  let max-number-value-in-list max list-of-values
  let list-of-keys-with-max-values []
  show (word "max =" max-number-value-in-list)
  foreach table:keys mtable [
    [key] ->
    let value table:get mtable key
    if(value = max-number-value-in-list)[
      show (word "adding value=" value " with key=" key " to list")
      show (word "list of values before = " list-of-keys-with-max-values)
      set list-of-keys-with-max-values (lput key list-of-keys-with-max-values)
      show (word "list of values = " list-of-keys-with-max-values)
    ]
  ]
  report list-of-keys-with-max-values
end

;Returns the direction of movement given two coordinates
to-report get-directions [x1 y1 x2 y2]
  report atan (x2 - x1) (y2 - y1)
end

to-report get-discrete-heading [angle]
  let i 0
  let mindiff 999
  let winner -1
  while [i < num-angles] [
    let a (i * 360 / num-angles)
    let diff (abs (angle - a))
    if (diff < mindiff) [
      set mindiff diff
      set winner i
    ]
    ;; show (word "i=" i " diff=" diff " a=" a)
    set i (i + 1)
  ]

  let angle-of-last-spoke ((num-angles - 1) * 360 / num-angles)
  ;; closes spoke appears to be last spoke, but angle is between
  ;; the last spoke and the first spoke... we need to check since
  ;; we might be closer to the first spoke
  if (winner = num-angles - 1) and (angle > angle-of-last-spoke) [
    let diff-to-first-spoke (360 - angle)
    if (diff-to-first-spoke < mindiff) [
      set winner 0
    ]
  ]
  report winner
end







;************** DIRECTION ***************
to-report set-get-directions-table
  let actionToDirectionAngle table:make
  table:put actionToDirectionAngle 0 0
  table:put actionToDirectionAngle 1 45
  table:put actionToDirectionAngle 2 90
  table:put actionToDirectionAngle 3 135
  table:put actionToDirectionAngle 4 180
  table:put actionToDirectionAngle 5 225
  table:put actionToDirectionAngle 6 270
  table:put actionToDirectionAngle 7 315
  report actionToDirectionAngle
end

;Returns #0-7: 8 possible directions
to-report get-discrete-heading2 [direction]
  let actionToDirectionAngle set-get-directions-table

  report direction mod 8
end



;Returns the direction of movement given two coordinates
to-report get-directions2 [x1 y1 x2 y2]
  if (x2 > x1) and (y2 > y1)
  [
    let y y2 - y1
    let x x2 - x1
    show "x2 and y2 greater"
    let dir get-discrete-heading atan x y
    report dir
  ]
  if (x1 > x2) and (y2 > y1)
  [
    let y y2 - y1
    let x x1 - x2
    show "x1 and y2 greater"
    let dir get-discrete-heading atan x y
    report dir
  ]
  if (x2 > x1) and (y1 > y2)
  [
    let y y1 - y2
    let x x2 - x1
    show "x2 and y1 greater"
    let dir get-discrete-heading atan x y
    report dir
  ]
  if (x1 > x2) and (y1 > y2)
  [
    let y y1 - y2
    let x x1 - x2
    show "x1 and y1 greater"
    let dir get-discrete-heading atan x y
    report dir
  ]
  if (x1 = x2) and (y2 > y1)
  [
    report 90
  ]
  if (x1 = x2) and (y1 > y2)
  [
    report 270
  ]
  if (x2 > x1) and (y1 = y2)
  [
    report 0
  ]
  if (x1 > x2) and (y1 = y2)
  [
    report 180
  ]

end

to go2
  ask turtles [
    let dir-stats (get-movement-stats xcor ycor vision-radius)

    if (length dir-stats > 0) [
      let new-dir (item 0 dir-stats)
      face-direction new-dir
    ]
    forward 1.0
  ]
  tick
end

@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
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
41
33
107
66
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
126
34
189
67
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
0

PLOT
688
64
888
214
Number of Deaths
time
deaths
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"turtles" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
27
128
199
161
number-of-people
number-of-people
0
100
25.0
1
1
NIL
HORIZONTAL

CHOOSER
44
177
182
222
age-ratio
age-ratio
"ageoldpeople" "75-0-25" "75250"
0

SLIDER
24
78
203
111
number-of-dangers
number-of-dangers
1
20
1.0
1
1
NIL
HORIZONTAL

PLOT
689
248
889
398
Number of Survivors
time
survivors
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

TEXTBOX
70
282
220
300
Young
11
105.0
1

TEXTBOX
66
307
216
325
Average
11
25.0
1

TEXTBOX
77
335
227
353
Old
11
55.0
1

TEXTBOX
8
239
210
281
The colors of the agents correspond to the following properties:
11
0.0
1

BUTTON
1003
72
1066
105
NIL
go2
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
928
158
1100
191
frac-old
frac-old
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
930
215
1102
248
frac-average
frac-average
0
100
54.0
1
1
NIL
HORIZONTAL

SLIDER
934
274
1106
307
frac-young
frac-young
0
100
16.0
1
1
NIL
HORIZONTAL

BUTTON
938
334
1062
367
NIL
normalize-pop
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
