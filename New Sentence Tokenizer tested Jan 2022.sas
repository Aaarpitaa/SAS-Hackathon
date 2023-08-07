/*  Team Server startup code */
cas casauto cassessopts=(caslib=casuser);
caslib _all_ assign;

/* You may not need this... it's running a compress and strip of whitespace /*
/* Dataset needs to be in active caslib! CASUSER! */
data casuser.DAIICHI_MS_2 (drop =content);
set public.DAIICHI_MS;
content1 = compress(content,, "kw");
content1=strip(content1);
run;

/* Set input parameters */
%let dsIn = "DAIICHI_MS_2";
%let docVar = "SubjectID";
%let textVar = "Medical_Summary";
%let output_facts_table_name = "DAIICHI_MS_SENT";

/* Rule for determining sentence boundaries */
data casuser.concept_rule;
   length rule $ 200;
   ruleId=1;
   rule='ENABLE:SentBoundaries';
   output;

   ruleId=2;
   /*rule='PREDICATE_RULE:SentBoundaries(first,last):(SENT,"_first{_w}","_last{_w}")'; */
   rule='PREDICATE_RULE:SentBoundaries(first,last):(SENT, (SENTSTART_1, "_first{_w}"), (SENTEND_1, "_last{_w}"))'; 
   output;
run;

proc cas;
textRuleDevelop.validateConcept / 
   table={name="concept_rule"}
   config='rule'
   ruleId='ruleId'
   casOut={name='outValidation',replace=TRUE}
;
run;
quit;

/* Compile concept rule; */
proc cas;
    loadactionset "textRuleDevelop";
    action compileConcept;
	param
   		table={name="concept_rule"}
   		config="rule"
   		enablePredefined=false
   		casOut={name="outli", replace=TRUE}
;
run;
quit;


/* Get Sentences */
proc cas;
textRuleScore.applyConcept / 
   table={name=&dsIn}
   docId=&docVar
   text=&textVar
   model={name="outli"}
   matchType="best"
   factOut={name=&output_facts_table_name, replace=TRUE, where="_fact_argument_=''"}
;
run;
quit;


proc cas;
   table.dropTable name="concept_rule" quiet=true; run;
   table.dropTable name="outli" quiet=true; run;
quit; 

proc casutil;
    save casdata="DAIICHI_MS_SENT" incaslib=CASUSER outcaslib=PUBLIC
     casout="DAIICHI_MS_SENT" compress replace;
quit;

/* This drops a unique ID at the sentence level */
data casuser.DAIICHI_MS_SENT_UID (compress = yes);
	set public.DAIICHI_MS_SENT;
		u_id = _n_;
		run;

/* This saves a permanent copy of your sentence level dataset */
proc casutil;
    save casdata="DAIICHI_MS_SENT_UID" incaslib=CASUSER outcaslib=PUBLIC
     casout="DAIICHI_MS_SENT_UID" compress replace;
quit;


