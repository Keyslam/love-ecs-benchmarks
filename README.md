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

## Running
To run the tests, do
```
lovec source [library] [entityLimit] [enableDrawing]
```
where `[library]` is the name of the library you want to test, `[entityLimit]` is the max number of entities to process at once (optional, defaults to `50,000`), and `[enableDrawing]` sets whether to draw sprites or not (optional, defaults to `false`).

## Results
```
50000 Entities

Concord: (Probably not accurate)
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
 Iteration: 0.0151 Seconds.
 Removal: 0.0238 Seconds.
 Min memory usage: 39.1 MB
 Peak memory usage: 97.7 MB
 
Cache: (Not accurate)
 Iteration: 0.0021 Seconds
 Removal: Not supported
 Min memory usage: 0.9 MB
 Peak memory usage: 1.4 MB
```

## Contributing
Feel free to add your own ECS library to the list, add features, or change the tests to be more idiomatic for their respective libraries.
