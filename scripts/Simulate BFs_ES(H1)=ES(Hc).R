source("scripts/functions.R")

## Data simulation 1: ES_Hi = ES_Hc 
#Conditions: 
# results in BF[studies, hypotheses, ratio H1:Hc, iter, sample size n]

#Simulation conditions --------------------------------------------------------
r2=.13 #effect size r-squared
pcor<-0.3 #correlation between the predictor variables
n<-c(100,350) #sample sizes
studies<-40 #number of studies
hypothesis<-"V1=V2=V3; V1>V2>V3" #tested hypotheses
models <- c("normal") #linear, logistic or probit regression


#specify number of iterations only if there is no object "iter" in the environment
if(!exists("iter")){
  iter<-1000 
}

#ratio between the regression coefficients b1:b2:b3>; larger number corresponds to larger coefficient
ratio_beta.Hi<-c(3,2,1)
ratio_beta.Hc<-c(1,2,3)

#determines the number of strudies from each population H1 or Hc:
#whether Hi:Hc = 1:1 or 3:1, respectively
ratio_HiHc<-c(2,4)

#Placeholder for the results-----------------------------------------------------
BF<-array(data = NA,
          dim=c(studies, 
                4, # hypotheses
                2, #1:1 or 3:1 ratio of studies coming from Hi and H
                iter,
                length(n) #different sample sizes
          ),
          dimnames = list(c(1:studies),
                          c("BF0u", "BFiu", "BFcu", "BFu"),
                          c("Hi:Hc=1:1","Hi:Hc=3:1"),
                          c(1:iter),
                          paste0("n = ", n)
          ))

#The BF of Hu is always 1
BF[,4,,,]<-1

#Simulation loop---------------------------------------------------------------
i<-1
s<-1
r<-1
t<-1

set.seed(123)

# loop to fill in BFiucu
for(i in 1:iter){
  
  for(s in 1:length(n)){
    
    for(r in 1:length(ratio_HiHc)){
      
      for(t in 1:studies){
        
        
        print(paste("Iteration i:",i, "Condition s:", s, "Study t:", t, "Ratio r:",r))
        
        #have ratio_beta conform with Hc or with Hi
        #Hi:Hc study ratio will be either 1:1 (every 2nd study comes from Hc)
        #or 1:3, every fourth study comes from Hc)
        if(t %% ratio_HiHc[r] == 0){ #2nd or 4th study => Hc
          ratio_beta<-ratio_beta.Hc
        }else{                       #else Hi
          ratio_beta<-ratio_beta.Hi 
        }
        
        #obtain BFiu
        BF[t,1:3,r,i,s]<-gen_dat(r2=r2,
                                 betas=coefs(r2, ratio_beta, cormat(pcor, length(ratio_beta)), "normal"),
                                 rho=cormat(pcor, length(ratio_beta)),
                                 n=n[s],
                                 "normal")%$%
          lm(Y ~ V1 + V2 +V3) %>%
          bain(hypothesis = hypothesis)%$%fit$BF.u[c(1,2,4)]
        
        
      } #end studies loop t
    }#end H1:Hc ratio loop r
  }# end sample size loop s
} #end iterations loop i

save.image(file="workspaces/Simulate BFs_ES(H1)=ES(Hc).RData")

