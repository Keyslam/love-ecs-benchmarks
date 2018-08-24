# love-ecs-benchmarks
Performance tests for various ECS libraries for LÖVE.

Currently tested libraries:
```
Concord
Nata
HooECS
Fangorn

+ a cache friendly ECS 
```

The benchmark is fairly simply and effectively consists of 2 parts: Iteration and removal.
Every frame 100 entities are created (up until a cap of 50000 entities).
These entities are moved to the bottom right edges of the screen.
If they go out of the screen bounds there is a 40% chance of them being deleted.
Otherwise they return to the 0, 0 position.

Each library is completely different, so this simple test gives us a broad result of how each library performs in a simple real life scenario.
Take these results with a grain of salt, and also take features in consideration.

# Results
```
50000 Entities

HooECS:
 Iteration: 0.0163 Seconds.
 Removal: 4.4251 Seconds.
 Min memory usage: 37.0
 Peak memory usage: 48.8MB

Fangorn:
 Iteration: 0.0151 Seconds.
 Removal: 0.0238 FPS.
 Min memory usage: 39.1 MB
 Peak memory usage: 97.7 MB
```
