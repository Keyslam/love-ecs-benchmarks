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
50000 Entities

Concord:
 Iteration: 0.0104 Seconds.
 Removal: 0.0172 Seconds.
 Min memory usage: 49.4 MB
 Peak memory usage: 98.6 MB

Nata:
 Iteration: 0.0131 Seconds.
 Removal: 0.0138 Seconds.
 Min Memory Usage: 17.6 MB
 Peak memory usage: 19.5 MB

HooECS:
 Iteration: 0.0163 Seconds.
 Removal: 4.4251 Seconds.
 Min memory usage: 37.0 MB
 Peak memory usage: 48.8 MB

Fangorn:
 Iteration: 0.0151 FPS.
 Removal: 0.0238 FPS.
 Min memory usage: 39.1 MB
 Peak memory usage: 97.7 MB
 
Cache:
 Iteration: 0.0021 Seconds
 Removal: Not supported
 Min memory usage: 0.9 MB
 Peak memory usage: 1.4 MB
```
