sink("diagnostics/m_lmer.txt")

library(RhpcBLASctl)

library(lme4)
library(nortest)
library(RPostgreSQL)

blas_set_num_threads(8)

#library("sp")

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv, dbname="kaggle")

query <- dbSendQuery(con, "
select
r.game_id,
r.season,
r.field as field,
r.team_id as team,
r.team_conf_id as o_conf,
r.opponent_id as opponent,
r.opponent_conf_id as d_conf,
r.game_length as game_length,
--ln(r.team_score::float) as log_ps
r.team_score::float as ps
from march_madness.m_results r

where
    r.season between 2016 and 2023
;")

games <- fetch(query,n=-1)

dim(games)

attach(games)

pll <- list()

# Fixed parameters

season <- as.factor(season)
#contrasts(year)<-'contr.sum'

field <- as.factor(field)
field <- relevel(field, ref = "none")

d_conf <- as.factor(d_conf)

o_conf <- as.factor(o_conf)

game_length <- as.factor(game_length)

fp <- data.frame(season,field,d_conf,o_conf,game_length)
fpn <- names(fp)

# Random parameters

game_id <- as.factor(game_id)
#contrasts(game_id) <- 'contr.sum'

offense <- as.factor(paste(season,"/",team,sep=""))
#contrasts(offense) <- 'contr.sum'

defense <- as.factor(paste(season,"/",opponent,sep=""))
#contrasts(defense) <- 'contr.sum'

rp <- data.frame(offense,defense)
rpn <- names(rp)

for (n in fpn) {
  df <- fp[[n]]
  level <- as.matrix(attributes(df)$levels)
  parameter <- rep(n,nrow(level))
  type <- rep("fixed",nrow(level))
  pll <- c(pll,list(data.frame(parameter,type,level)))
}

for (n in rpn) {
  df <- rp[[n]]
  level <- as.matrix(attributes(df)$levels)
  parameter <- rep(n,nrow(level))
  type <- rep("random",nrow(level))
  pll <- c(pll,list(data.frame(parameter,type,level)))
}

# Model parameters

parameter_levels <- as.data.frame(do.call("rbind",pll))
dbWriteTable(con,c("march_madness","m_parameter_levels"),parameter_levels,row.names=TRUE)

g <- cbind(fp,rp)

g$ps <- ps

dim(g)

#model0 <- log_ps ~ year+field+d_conf+o_conf+(1|offense)+(1|defense)
#fit0 <- lmer(model0, data=g, REML=FALSE, verbose=TRUE)

model <- ps ~ season+field+d_conf+o_conf+game_length+(1|offense)+(1|defense)+(1|game_id)
fit <- glmer(model, data=g, verbose=TRUE, family=poisson(link=log),
            #control=glmerControl(calc.derivs = FALSE))
            nAGQ=0,
            control=glmerControl(optimizer = "nloptwrap"))

fit
summary(fit)

#anova(fit0)
anova(fit)
#anova(fit0,fit)

# List of data frames

# Fixed factors

f <- fixef(fit)
fn <- names(f)

# Random factors

r <- ranef(fit, condVar = FALSE)
rn <- names(r) 

results <- list()

for (n in fn) {

  df <- f[[n]]

  factor <- n
  level <- n
  type <- "fixed"
  estimate <- df

  results <- c(results,list(data.frame(factor,type,level,estimate)))

 }

for (n in rn) {

  df <- r[[n]]

  factor <- rep(n,nrow(df))
  type <- rep("random",nrow(df))
  level <- row.names(df)
  estimate <- df[,1]

  results <- c(results,list(data.frame(factor,type,level,estimate)))

 }

combined <- as.data.frame(do.call("rbind",results))

dbWriteTable(con,c("march_madness","m_basic_factors"),as.data.frame(combined),row.names=TRUE)

f <- fitted(fit) 
r <- residuals(fit)

# Jackknife - 4500 data points 1000 times

subs=4500
iter=1000

# Vector of results

pvals=rep(NA, iter)

# Sample p-values

for(i in 1:iter){
samp=sample(1:length(r),4500)
p.i=sf.test(r[samp])$p.value
pvals[i]=p.i
}

# Sampled p-value statistics

mean(pvals)
median(pvals)
sd(pvals)

# Graph p-values

jpeg("diagnostics/m_shapiro-francia.jpg")
hist(pvals,xlim=c(0,1))
abline(v=0.05,lty='dashed',lwd=2,col='red')
quantile(pvals,prob=seq(0,1,0.05))

# Examine residuals

jpeg("diagnostics/m_fitted_vs_residuals.jpg")
plot(f,r)
jpeg("diagnostics/m_q-q_plot.jpg")
qqnorm(r,main="Q-Q plot for residuals")

quit("no")
