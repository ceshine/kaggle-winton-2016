# Suppress scientific notation
options(scipen=1)

# Make sure pacman is installed
install.packages("pacman")

# Load the required libraries
pacman::p_load(rstan)
pacman::p_load(data.table)

# Optional: using multi-cores (requires extra memory space)
options(mc.cores=parallel::detectCores())

train_data <- fread("data/train.csv")
test_data <- fread("data/test_2.csv")
train_data[is.na(train_data)] <- 0
test_data[is.na(test_data)] <- 0

train_data[, x_2 := Ret_MinusOne]
test_data[, x_2 := Ret_MinusOne]

# Add intra-day returns into x_2
for(i in 2:120){
  stopifnot(train_data[is.na(get(paste("Ret_", i, sep=""))), .N] == 0)
  stopifnot(train_data[is.na(get(paste("Ret_", i, sep=""))), .N] == 0)
  train_data[, x_2 := x_2 + get(paste("Ret_", i, sep=""))]
  test_data[, x_2 := x_2 + get(paste("Ret_", i, sep=""))]
}

# Predict PlusOne returns
fit <- stan(file = 'stan_model.stan',
            data = list(
              x_1 = train_data$Ret_MinusTwo,
              x_2 = train_data$x_2,
              x_1_test = test_data$Ret_MinusTwo,
              x_2_test = test_data$x_2,
              t = train_data$Ret_PlusOne,
              N_test = test_data[, .N],
              df = 2.6,
              N = train_data[, .N]),
              iter = 1000, chains = 4)

print(fit, probs=c(0.1, 0.5, 0.9))
params <- extract(fit, par=c("t_pred", "w_1_0", "w_1_1", "w_1_2"))

save(params, file="plusone.RData")

test_data[,preds_plusone:=apply(data.table(t(params$t_pred)), 1, mean)]

rm(fit, params)
gc(T)

# Predict PlusTwo Returns
fit <- stan(file = 'stan_model.stan',
            data = list(
              x_1 = train_data$Ret_MinusTwo,
              x_2 = train_data$x_2,
              x_1_test = test_data$Ret_MinusTwo,
              x_2_test = test_data$x_2,
              t = train_data$Ret_PlusTwo,
              N_test = test_data[, .N],
              df = 2.6,
              N = train_data[, .N]),
            iter = 1000, chains = 4)

print(fit, probs=c(0.1, 0.5, 0.9))
params <- extract(fit, par=c("t_pred", "w_1_0", "w_1_1", "w_1_2"))

save(params, file="plustwo.RData")

test_data[,preds.plustwo:=apply(data.table(t(params$t_pred)), 1, mean)]

sub <- fread("data/sample_submission_2.csv")
sub <- sub[!grep("_(61|62)$", Id), ]

sub <- rbind(sub, test_data[, .(Id=paste(Id, 61, sep="_"), Predicted=preds_plusone)])
sub <- rbind(sub, test_data[, .(Id=paste(Id, 62, sep="_"), Predicted=preds_plustwo)])

write.csv(sub, file="sub.csv", row.names=F)
