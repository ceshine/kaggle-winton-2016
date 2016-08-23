data { 
  int<lower=0> N; 
  vector[N] t; // Ret Plus One / Ret Plus two
  vector[N] x_1; //Ret Minus Two
  vector[N] x_2; //Ret Minus + First 120 mins
  int<lower=0> N_test;
  vector[N_test] x_1_test;
  vector[N_test] x_2_test;
  real df; // Degrees of freedom (2.6)
} 

parameters { 
  real w_1_0; 
  real w_1_1; 
  real w_1_2; 
  real<lower=0> alpha; 
  real<lower=0> beta; 
} 

transformed parameters { 
  real<lower=0> sigma_w; 
  real<lower=0> sigma_t; 
  sigma_w = sqrt(alpha); 
  sigma_t = sqrt(beta); 
} 

model { 
  w_1_0 ~ normal(0,sigma_w);
  w_1_1 ~ normal(0,sigma_w); 
  w_1_2 ~ normal(0,sigma_w); 
  alpha ~ inv_gamma(1E-2, 1E-4); 
  beta ~ inv_gamma(.3, .0001); 
  t ~ student_t(df, w_1_0+w_1_1*x_1+w_1_2*x_2, sigma_t); 
}

generated quantities{
  vector[N_test] t_pred;
  t_pred = w_1_0+w_1_1*x_1_test+w_1_2*x_2_test;
}
