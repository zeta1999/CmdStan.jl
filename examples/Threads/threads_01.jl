# Experimental threads example. WIP!

using CmdStan
#using Distributed
using Statistics
using StatsBase: sample

ProjDir = mktempdir()
cd(ProjDir) #do

bernoullimodel = "
data { 
  int<lower=1> N; 
  int<lower=0,upper=1> y[N];
} 
parameters {
  real<lower=0,upper=1> theta;
} 
model {
  theta ~ beta(1,1);
  y ~ bernoulli(theta);
}
";
n = 10;
observeddata = Dict("N" => n, "y" => sample([0,1],n))

sm = Stanmodel(name="bernoulli", model=bernoullimodel;
  output_format=:namedtuple);

println("\nThreads loop\n")
p1 = 16 # p1 is the number of models to fit
estimates = Vector(undef, p1)
Threads.@threads for i in 1:p1
    pdir = pwd()
    while ispath(pdir)
        pdir = tempname()
    end
    println(pdir)

    new_model= deepcopy(sm)
    new_model.pdir = pdir
    new_model.tmpdir = joinpath(splitpath(pdir)...,"tmp")
    
    mkpath(new_model.tmpdir)

    CmdStan.update_model_file(joinpath(new_model.tmpdir, "$(new_model.name).stan"), strip(new_model.model))

    rc, samples, cnames = stan(new_model, observeddata, new_model.pdir;
    #  summary=false
    );

    if rc == 0
      estimates[i] = [mean(reshape(samples.theta, 4000)), std(reshape(samples.theta, 4000))]
    end

    #rm(pdir; force=true, recursive=true)
end

estimates |> display

#end
