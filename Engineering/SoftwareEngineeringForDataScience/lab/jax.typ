#set page(
  paper: "us-letter",
  header: align(center, text(17pt)[
    *Jax*
  ]),
  numbering: "1",
)

#import "../style.typ": style_template
#show: doc => style_template(doc,)

= Foreword

My first encounter with `Jax` was in 2018

= What is Jax

== python on steroid

Syntax-wise `jax` is `python`, even though there are patterns that are encouraged and discouraged in `jax` that requires a different mindset comparing to a normal `python` code.

== XLA

= Core features

== jit

The first feature you may want to use in `jax` is its just-in-time compilation feature. Let's look at an example first:

```python
import numpy as np
import jax
import jax.numpy as jnp

def selu(x, alpha=1.67, lambda_=1.05):
  return lambda_ * jnp.where(x > 0, x, alpha * jnp.exp(x) - alpha)

def selu_numpy(x, alpha=1.67, lambda_=1.05):
  return lambda_ * np.where(x > 0, x, alpha * np.exp(x) - alpha)

selu_jit = jax.jit(selu)
x = jnp.arange(1000000)
%timeit selu(x).block_until_ready()
%timeit selu_jit(x).block_until_ready()

y = np.arange(1000000)
%timeit selu_numpy(y)
```

Here we create three version of the `selu` function, which is a commonly used activation function in deep learning. The first one is the `jax` version without any optimization, the second one is the `jax` version with `jit` optimization, and the last one is the `numpy` version. Similar to `julia`, the first time you call a jit function will have the compilation overhead. Unlike `julia`, you can choose to compile a function or not, whereas in `julia`, everything is compiled.

Benchmark the three functions, and we can see that the `jit` version is faster than the non-optimized version, and the `numpy` version is slower than the non-optimized version. Why is this the case? There are mainly two factors why this could be the case. The first reason is `jax` can interface seamlessly with `XLA`, which is a compiler that is designed to compile efficient code for accelerators. This compilation produces more optimized code by fusing operations such that the execution time and memory footprint are reduced. Another reason is without changing the source code, your program can run on a GPU or TPU, which makes large and dense computation much faster.

While jitting generally provide performance boost, it is not always the case. For example, if the function is very simple, the communication overhead between the CPU and the accelerator may outweigh the performance gain from the compilation. But this is usually a corner case that is not very practical, so while keeping that in mind, try jitting whenever you can.

== grad

Another awesome feature jax provides is automatic differentiation. Again, let's first look at how it works:

```python
import jax
import jax.numpy as jnp

def tanh(x):
  return (jnp.exp(x) - jnp.exp(-x)) / (jnp.exp(x) + jnp.exp(-x))

d_tanh = jax.grad(tanh)
assert d_tanh(1.57) == (1./jnp.cosh(1.54))
```

Given a function `f` that is compatible with `jax`, then `jax.grad(f)` returns a function that will return the gradient of `f` with respect to its arguments. If this is not magical enough, the runtime of the gradient function is usually linear in the number of arguments instead of geometric like finite differencing, and the accuracy is usually as accurate as the function itself! How is this even possible?

The idea behind autodiff is basically just chain rules. Say I have a function `sin(x)`, we know exactly it's derivative, which is `cos(x)`. Now if I build on top of the function and I want its gradient with respect to its input, then I just need to apply chain rule and multiply the jacobian I get at each stage. There are a lot of infrastructure behind the scene to make the efficient, but this is the crux of autodiff.

== vmap

The third vanilla feature we will learn here is `vmap`, and here is how it looks like:

```python
def my_function(x, y):
  return x@y

x = jnp.arange(100)
y = jnp.eye(100)

my_function(x, y)

x_batch = x[None].repeat(10, axis=0)
y_batch = y[None].repeat(10, axis=0)

jax.vmap(my_function)(x_batch, y_batch)
```

`jax.vmap` takes a function as an argument then return a function that add a batch dimension to all of the function's argument, and return that new function as its result. If you want to map over different axis of your input, you can use the `in_axes` argument in `vmap` You can find more detail in the #link("")[link]. 
If you have ever come across the function `np.vectorize`, you can read from their documentation that `np.vectorize` is actually just a for-loop. While `vmap` achieve the same thing in terms of function signature, the underlying computation is completely different. Since `np.vectorize` is essentially a for-loop, the runtime of the vectorized function is linear in the batch dimension. However, `vmap` add extra annotation to the function before dispatching it to the `XLA`, telling the runtime the newly added batch axis can be parallelized, a vmapped function could be executed just as fast as the original function in most cases, as long as you are not memory bounded by your resource. This means we can acheive much higher throughput while not paying extra time cost. The cost we have to be mindful here is memory, since you are essentially parallelizing over one axis, you are computing more stuff at one time, meaning you will need more memory to store the input and the result.

= Sharp bits

While `jax` offers a lot of good features that you should use, it does have some sharpbits that could be a bit unintuitive if you have not worked with these kinds of code transformation libraries.

== Jax only

Now you may be wondering how the compiler knows about the gradient of the function you have just coded up, while you are pretty this is a completely original piece code.The answer lies in the fact that ultimately the functions or "primitives" you are allowed to use to construct your original function be known to `jax` already. For example, if you have a function that uses `np.sin`, you must replace it with something `jax` is aware of its internel, in this case `jnp.sin`. If you have functions which `jax` do not know the internel of the function, then `jax` will not be able to convert the function automatically.

The implication of this that needed to be transform has to be in `jax`. If you find a package online that is pretty neat, but it does not use `jax` as its dependencies, you either need to expose the internal of the code to `jax`, or just rewrite the thing in `jax`. 

== Control flows

== Dynamic allocation is prohibited

In order to efficiently work with accelerators, `jax` aggressively hates any dynamic allocation, i.e. functions that do not know how much memory it will need at compile time. This means in your function, you are almost never allow to something that will change in shape.

== Long compilation with for loop

While `jax` can provide really good run time performance, and most deep learning practitioners will not be acutely aware of the compilation overhead, the compilation overhead can be pretty annoying when it comes to scientific computing. The difference between deep learning and scientific computing is despite being compute heavy, deep neural network are very simple program. The core of many neural network are just matrix multiplication, so there are not many lines to the program. On the other hand, scientific programs often come with a wide variety of forms, and there could be many interdependent modules, hence often way more lines of code involved. At its core, `jax`'s `jit` system is still running on `python`, and overhead related to `python` could make compilation slow. To make it worse, for loops are quite common in scientific computing, and if one naively write a for loop and trying to compile it in `jax`, `jax` will unroll the whole for loop and inline everything. This means the compilation time of your program scales linear as the number of loops you have. One example is when I first tried `jax` in 2018, I was writing a numerical relativity simulation in `jax`, hoping to capitalize on the use of accelerator from `jax`. While the simulation runtime is much faster than alternatives (30 minutes vs a couple of hours), the compilation time is about 2 hours long, which completely defeat the point of having a fast code. In a later section, we will see what is the recommended way to write such operation.

= Ecosystem

== jaxtyping

== Equinox

== Diffrax

= Modeling a pendulum

== Step 1: Solving the dynamics

== Step 2: Rendering an animation

== Step 3: Creating our data

= Building a neural network with `Equinox`

While I love using `jax` for scientific computing, in the past I found using it for building neural network quite unintuitive and clumpsy. `jax` relies on the computation we want to execute being a pure function in order to apply its code transformation capbility, so 

= Learning the coefficient of an ODE

= Best practices

== Avoiding in-place mutation

== Scan your for loop

== Think like a GPU

== jit at top level

== check your gradient
