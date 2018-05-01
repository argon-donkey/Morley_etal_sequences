#### Dan's Coevo Data

rm(list=ls())

library(survival)
library(rms)
library(car)
library(multcomp)
library(relaimpo)
library(dplyr)
library(magrittr)

setwd("./phage_survival/analysis_data/phage_surv.csv")

## Survival analyses

phage<-read.csv("./phage_survival/analysis_data/phage_surv.csv", header=T)
phage$replicate %<>% as.factor()
phage$treatment %<>% as.factor()
attach(phage)
names(phage)

summary(KM<-survfit(Surv(time_to_death,status)~1))
plot(KM, ylab="Survivorship", xlab="Transfer")

# KM ~ group
summary(KM<-survfit(Surv(time_to_death,status)~treatment))

jpeg("./figs/survplot.jpg", width=20, height=15, units="in", res=300)
par(mfrow=c(1,1), xpd=TRUE, oma=c(1,1,1,1), mai=c(1.02,.1,.82,0), bty="l", pty="s")

plot(survfit(Surv(phage$time_to_death,phage$status)~treatment), lty=c(1,3,5,6), 
     lwd=c(5,5,5,5), ylab="", xlab="", axes=FALSE, ylim=c(0,1), xlim=c(0,30))

axis(1, tcl=-0.1, pos=0, cex.axis=1, lwd=c(3), cex.axis=2)
axis(1, at=15, lab="Transfer", tcl=0, line=2, cex.axis=3)

axis(2, tcl=-0.1, pos=0, cex.axis=1, las=2, lwd=c(3), cex.axis = 2)
axis(2, at=0.5, lab="Proportion of replicates\nwith surviving phage", line=5, cex.axis=3, tcl=0)

legend(20,1, bty="o", title=c("Treatment"),
       legend=c(expression("10"*{}^{9}*""), 
                expression("10"*{}^{8}*""), 
                expression("10"*{}^{7}*""), 
                expression("10"*{}^{6}*"")),
       lty=c(6,5,3,1), lwd=c(5,5,5,5), cex=3, adj=0)

dev.off()

print(KM, print.rmean=T)

# Cox proportional hazards model
cosph.mod<-coxph(Surv(time_to_death,status)~treatment)
summary(cosph.mod)
cosph.mod$loglik

anova(cosph.mod)
tapply(predict(cosph.mod),treatment,mean)

tukey <- summary(glht(cosph.mod, linfct = mcp(treatment = "Tukey")))
HRs <- exp(tukey$test$coefficients)
SEs <- exp(tukey$test$sigma)
Z <- tukey$test$tstat
P <- tukey$test$pvalues
HRs <- data.frame(HRs, SEs, Z, P)
clip = pipe('pbcopy', 'w')
write.table(HRs, file=clip, sep='\t', row.names = F, col.names = F)
close(clip)

plot(survfit(cosph.mod), xlim=c(0,30), lty=c(1,2,3))