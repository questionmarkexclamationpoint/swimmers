require 'distribution'
module Util
  NormalDistributionGenerator = Distribution::Normal.rng
  
  def self.sigmoid(x)
    1.0 / (1.0 + Math::E ** (-x.to_f))
  end
  def self.sigmoid_prime(x)
    (Math::E ** x.to_f) / ((Math::E ** x.to_f + 1) ** 2)
  end
  def self.random_normal
    NormalDistributionGenerator.call
  end
  def self.cost_derivative(x, y)
    x - y
  end
end
