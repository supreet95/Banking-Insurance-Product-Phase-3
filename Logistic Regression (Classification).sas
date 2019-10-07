


options validvarname=V7;

/* import training data */
proc import datafile="C:/Users/iaa-student/Documents/SAS Programming/LR/Final_data.xlsx"
	out = work.train
	dbms = xlsx
	replace;
run;

/* import validation data */
proc import datafile="C:/Users/iaa-student/Documents/SAS Programming/LR/Validation_data.xlsx"
	out = work.validation
	dbms = xlsx
	replace;
run;

/* drop variables with missing values in training set */
data work.train;
	set work.train;
	drop INV CC HMOWN CCPURC CASHBK MMCRED;
run;


/* drop variables with missing values in validation set */
data work.validation;
	set work.validation;
	drop INV CC HMOWN CCPURC CASHBK MMCRED;
run;

/* concordance percentage */
proc logistic data=train;
	class BRANCH CC_c INV_c ATMAMT_Bin CDBAL_Bin CHECKS_Bin DDABAL_Bin MMBAL_Bin
	SAVBAL_Bin TELLER_Bin DDA ILS IRA NSF / param=ref;
	model ins(event='1') = BRANCH CC_c INV_c ATMAMT_Bin CDBAL_Bin CHECKS_Bin DDABAL_Bin MMBAL_Bin DDABAL_Bin*MMBAL_Bin
	SAVBAL_Bin DDABAL_Bin*SAVBAL_Bin TELLER_Bin DDA ILS IRA DDA*IRA NSF;
	output out=predprobs p=phat;
run;

/* discrimination slope */
proc sort data=predprobs;
	by descending ins;
run;

proc ttest data=predprobs order=data;
	ods select statistics summarypanel;
	class ins;
	var phat;
	title 'Coefficient of Discrimination and Plots';
run;

/* ROC curve */
proc logistic data=train plots(only)=ROC;
	class BRANCH CC_c INV_c ATMAMT_Bin CDBAL_Bin CHECKS_Bin DDABAL_Bin MMBAL_Bin
	SAVBAL_Bin TELLER_Bin DDA ILS IRA NSF / param=ref;
	model ins(event='1') = BRANCH CC_c INV_c ATMAMT_Bin CDBAL_Bin CHECKS_Bin DDABAL_Bin MMBAL_Bin DDABAL_Bin*MMBAL_Bin
	SAVBAL_Bin DDABAL_Bin*SAVBAL_Bin TELLER_Bin DDA ILS IRA DDA*IRA NSF / clodds=pl clparm=pl;
	output out=predprobs p=phat;
run;

/* K-S statistic */
proc npar1way data=predprobs d plot=edfplot;
	class ins;
	var phat;
run;

/* train model and score on validation for confusion matrix and lift */
proc logistic data=train plots(only)=(oddsratio);
	class BRANCH CC_c INV_c ATMAMT_Bin CDBAL_Bin CHECKS_Bin DDABAL_Bin MMBAL_Bin
	SAVBAL_Bin TELLER_Bin DDA ILS IRA NSF / param=ref;
	model ins(event='1') = BRANCH CC_c INV_c ATMAMT_Bin CDBAL_Bin CHECKS_Bin DDABAL_Bin MMBAL_Bin DDABAL_Bin*MMBAL_Bin
	SAVBAL_Bin DDABAL_Bin*SAVBAL_Bin TELLER_Bin DDA ILS IRA DDA*IRA NSF / clodds=pl clparm=pl;
	score data=validation fitstat out=scores outroc=roc;
run;

/* modify roc data set to calculate lift */
data work.roc;
	set work.roc;
	cutoff = _PROB_;
	specif = 1-_1MSPEC_;
	depth=(_POS_+_FALPOS_)/(2124)*100;
	precision=_POS_/(_POS_+_FALPOS_);
	acc=_POS_+_NEG_;
	lift=precision/(3660/10619);
run;

/* export scores data set to excel file - calculate confusion matrix in excel */
proc export data=work.scores
	outfile='C:/Users/iaa-student/Documents/SAS Programming/LR/scores.xlsx'
	dbms=xlsx
	replace;
run;

/* export roc data set to excel file */
proc export data=work.roc
	outfile='C:/Users/iaa-student/Documents/SAS Programming/LR/roc.xlsx'
	dbms=xlsx
	replace;
run;

/* plot lift */
proc sgplot data=roc;
	series x=depth y=lift;
run;

