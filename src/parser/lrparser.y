 %{
	
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include <stdbool.h>
    #include "includeHeader.hpp"
	//#include "y.tab.h"
     
	void yyerror(char *);
	int yylex(void);
    extern FILE* yyin;

	char mytext[100];
	char var[100];
	int num = 0;
	extern char *yytext;
	extern SymbolTable* symbTab;
	FrontEndContext *FrontEndContext::instance=0;
    //symbTab=new SymbolTable();
	//symbolTableList.push_back(new SymbolTable());
%}

/* This is the yacc file in use for the DSL. The action part needs to be modified completely*/

%union {
    int  info;
    long ival;
	bool bval;
    double fval;
    char* text;
	ASTNode* node;
	paramList* pList;
	argList* aList;
	ASTNodeList* nodeList;
    tempNode* temporary;
     }
%token T_INT T_FLOAT T_BOOL T_DOUBLE  T_LONG
%token T_FORALL T_FOR  T_P_INF  T_INF T_N_INF
%token T_FUNC T_IF T_ELSE T_WHILE T_RETURN T_DO T_IN T_FIXEDPOINT T_UNTIL T_FILTER
%token T_ADD_ASSIGN T_SUB_ASSIGN T_MUL_ASSIGN T_DIV_ASSIGN T_MOD_ASSIGN T_AND_ASSIGN T_XOR_ASSIGN
%token T_OR_ASSIGN T_RIGHT_OP T_LEFT_OP T_INC_OP T_DEC_OP T_PTR_OP T_AND_OP T_OR_OP T_LE_OP T_GE_OP T_EQ_OP T_NE_OP
%token T_AND T_OR T_SUM T_AVG T_COUNT T_PRODUCT T_MAX T_MIN
%token T_GRAPH T_DIR_GRAPH  T_NODE T_EDGE
%token T_NP  T_EP
%token T_LIST T_SET_NODES T_SET_EDGES T_ELEMENTS T_FROM
%token T_BFS T_REVERSE

%token T_NBHRS T_NFRM T_NTO T_OUTD T_IND T_ONBHRS T_INBHRS T_EFRM T_ETO
%token T_GTSRC T_GTDEST T_GTEDGE T_GTNBHR 
%token T_ADD_NODE T_ADD_NODES T_ADD_EDGE T_ADD_EDGES T_REM_NODE T_REM_NODES T_REM_EDGE T_REM_EDGES
%token T_CONTAINS T_DISCARD T_TOT_ELEMS T_ISEMP T_CLR 
%token T_ADD_NODE T_ADD_NODESET
%token T_ADD_EDGE T_ADD_EDGESET

%token <text> ID
%token <ival> INT_NUM
%token <fval> FLOAT_NUM
%token <bval> BOOL_VAL

%type <node> function_def function_data function_body param
%type <pList> paramList
%type <node> statement blockstatements assignment declaration proc_call control_flow reduction
%type <node> type1 type2
%type <node> primitive graph collections property
%type <node> leftSide rhs expression oid val boolean_expr tid
%type <node> bfs_abstraction filterExpr reverse_abstraction
%type <nodeList> leftList
%type <node> iteration_cf selection_cf
%type <node> reductionCall
%type <aList> arg_list
%type <ival> reduction_op
%type <temporary>  rightList




 /* operator precedence
  * Lower is higher
  */
%left '?'
%left ':'
%left T_OR_OP
%left T_AND_OP
%left T_EQ_OP  T_NE_OP
%left '<' '>'  T_LE_OP T_GE_OP
%left '+' '-'
%left '*' '/' '%'


%%
program: function_def {printf("program.\n");};

function_def: function_data  function_body  { };

function_data: T_FUNC ID '(' paramList ')' {Identifier* funcId=(Identifier*)Util::createIdentifierNode($2);
                                           $$=Util::createFuncNode(funcId,$4->PList); };

paramList: param {$$=Util::createPList($1);};
               | param ',' paramList {$$=Util::addToPList($3,$1); };

param : type1 ID {  Identifier* id=(Identifier*)Util::createIdentifierNode($2);
                    $$=Util::createParamNode($1,id); } ;
               | type2 ID {  Identifier* id=(Identifier*)Util::createIdentifierNode($2);
                             $$=Util::createParamNode($1,id);};
			   | type2 ID '(' ID ')' {  Identifier* id1=(Identifier*)Util::createIdentifierNode($4);
			                            Identifier* id=(Identifier*)Util::createIdentifierNode($2);
				                        Type* tempType=(Type*)$1;
			                            if(tempType->isNodeEdgeType())
										   tempType->addSourceGraph(id1);
				                         $$=Util::createParamNode(tempType,id);
									 };


function_body : blockstatements {$$=$1;};


statements :  {};
	| statements statement { Util::addToBlock($2); };

statement: declaration ';'{printf("testdeclr\n");$$=$1;};
	|assignment ';'{$$=$1;};
	|proc_call ';' {printf("testprocstmt\n");$$=Util::createNodeForProcCallStmt($1);};
	|control_flow {$$=$1;};
	|reduction ';'{$$=$1;};
	| bfs_abstraction {$$=$1; };
	| reverse_abstraction {$$=$1; };
	| blockstatements {$$=$1;};


blockstatements : block_begin statements block_end { $$=Util::finishBlock();};

block_begin:'{' { Util::createNewBlock(); }

block_end:'}'


declaration : type1 ID   {Identifier* id=(Identifier*)Util::createIdentifierNode($2);
                         $$=Util::createNormalDeclNode($1,id);};
	| type1 ID '=' rhs  {Identifier* id=(Identifier*)Util::createIdentifierNode($2);
	                    $$=Util::createAssignedDeclNode($1,id,$4);};
	| type2 ID  {Identifier* id=(Identifier*)Util::createIdentifierNode($2);
                         $$=Util::createNormalDeclNode($1,id); };
	| type2 ID '=' rhs {Identifier* id=(Identifier*)Util::createIdentifierNode($2);
	                    $$=Util::createAssignedDeclNode($1,id,$4);};

type1: primitive {$$=$1; };
	| graph {$$=$1;};
	| collections { $$=$1;};


primitive: T_INT { $$=Util::createPrimitiveTypeNode(TYPE_INT);};
	| T_FLOAT { $$=Util::createPrimitiveTypeNode(TYPE_FLOAT);};
	| T_BOOL { $$=Util::createPrimitiveTypeNode(TYPE_BOOL);};
	| T_DOUBLE { $$=Util::createPrimitiveTypeNode(TYPE_DOUBLE); };
    | T_LONG {$$=$$=Util::createPrimitiveTypeNode(TYPE_LONG);};

graph : T_GRAPH { $$=Util::createGraphTypeNode(TYPE_GRAPH,NULL);};
	|T_DIR_GRAPH {$$=Util::createGraphTypeNode(TYPE_DIRGRAPH,NULL);};

collections : T_LIST { $$=Util::createCollectionTypeNode(TYPE_LIST,NULL);};
		|T_SET_NODES '<' ID '>' {Identifier* id=(Identifier*)Util::createIdentifierNode($3);
			                     $$=Util::createCollectionTypeNode(TYPE_SETN,id);};
                | T_SET_EDGES '<' ID '>' { Identifier* id=(Identifier*)Util::createIdentifierNode($3);
					                    $$=Util::createCollectionTypeNode(TYPE_SETE,id);};

type2 : T_NODE {$$=Util::createNodeEdgeTypeNode(TYPE_NODE) ;};
       | T_EDGE {$$=Util::createNodeEdgeTypeNode(TYPE_EDGE);};
	   | property {$$=$1;};

property : T_NP '<' primitive '>' { $$=Util::createPropertyTypeNode(PROP_NODE,$3); };
              | T_EP '<' primitive '>' { $$=Util::createPropertyTypeNode(PROP_EDGE,$3); };
			  | T_NP '<' collections '>'{  $$=Util::createPropertyTypeNode(PROP_NODE,$3); };
			  | T_EP '<' collections '>' {$$=Util::createPropertyTypeNode(PROP_EDGE,$3);};

assignment :  leftSide '=' rhs  { printf("testassign\n");$$=Util::createAssignmentNode($1,$3);};

rhs : expression { $$=$1;};

expression : proc_call { $$=$1;};
             | expression '+' expression { $$=Util::createNodeForArithmeticExpr($1,$3,OPERATOR_ADD);};
	         | expression '-' expression { $$=Util::createNodeForArithmeticExpr($1,$3,OPERATOR_SUB);};
	         | expression '*' expression {$$=Util::createNodeForArithmeticExpr($1,$3,OPERATOR_MUL);};
	         | expression'/' expression{$$=Util::createNodeForArithmeticExpr($1,$3,OPERATOR_DIV);};
             | expression T_AND_OP expression {$$=Util::createNodeForLogicalExpr($1,$3,OPERATOR_AND);};
	         | expression T_OR_OP  expression {$$=Util::createNodeForLogicalExpr($1,$3,OPERATOR_OR);};
	         | expression T_LE_OP expression {$$=Util::createNodeForRelationalExpr($1,$3,OPERATOR_LE);};
	         | expression T_GE_OP expression{$$=Util::createNodeForRelationalExpr($1,$3,OPERATOR_GE);};
			 | expression '<' expression{$$=Util::createNodeForRelationalExpr($1,$3,OPERATOR_LT);};
			 | expression '>' expression{$$=Util::createNodeForRelationalExpr($1,$3,OPERATOR_GT);};
			 | expression T_EQ_OP expression{$$=Util::createNodeForRelationalExpr($1,$3,OPERATOR_EQ);};
             | expression T_NE_OP expression{$$=Util::createNodeForRelationalExpr($1,$3,OPERATOR_NE);};
		| '(' expression ')' {$$=$2;};
	         | val {$$=$1;};
			 | leftSide { $$=$1 ;};

proc_call : leftSide '(' arg_list ')' {printf("testproc\n"); $$=Util::createNodeForProcCall($1,$3->AList); };
		



val : INT_NUM { printf("Hi");
                $$=Util::createNodeForIval($1); };
	| FLOAT_NUM {$$=Util::createNodeForFval($1);};
	| BOOL_VAL {$$=Util::createNodeForBval($1);};
	| T_INF {$$=Util::createNodeForINF(true);};
	| T_P_INF {$$=Util::createNodeForINF(true);};
	| T_N_INF {$$=Util::createNodeForINF(false);};

control_flow : selection_cf { $$=$1; };
              | iteration_cf { $$=$1; };

iteration_cf : T_FIXEDPOINT T_UNTIL '(' boolean_expr ')' blockstatements { $$=Util::createNodeForFixedPointStmt($4,$6);};
		   | T_WHILE '(' boolean_expr')' blockstatements {$$=Util::createNodeForWhileStmt($3,$5); };
		   | T_DO blockstatements T_WHILE '(' boolean_expr ')' {$$=Util::createNodeForDoWhileStmt($5,$2);  };
		| T_FORALL '(' ID T_IN ID '.' proc_call filterExpr')'  blockstatements {$$=Util::createNodeForForAllStmt($3,$5,$7,$8,$10,true);};
		| T_FOR '(' ID T_IN leftSide ')' blockstatements {$$=Util::createNodeForForStmt($3,$5,$7,false);};
		| T_FOR '(' ID T_IN ID '.' proc_call  filterExpr')' blockstatements {$$=Util::createNodeForForAllStmt($3,$5,$7,$8,$10,false);};

filterExpr  :         { $$=NULL;};
            |'.' T_FILTER '(' boolean_expr ')'{ $$=$4;};

boolean_expr : expression { $$=$1 ;};

selection_cf : T_IF '(' boolean_expr ')' blockstatements { $$=Util::createNodeForIfStmt($3,$5,NULL); };
	           | T_IF '(' boolean_expr ')' blockstatements T_ELSE blockstatements  {$$=Util::createNodeForIfStmt($3,$5,$7); };


reduction : leftSide '=' reductionCall { $$=Util::createNodeForReductionStmt($1,$3) ;}
		   |'<' leftList '>' '=' '<' rightList '>'  {$$=Util::createNodeForReductionStmtList($2->ASTNList,$6->reducCall,$6->exprVal);};

leftList :  leftSide ',' leftList { $$=Util::addToNList($3,$1);};
		 | leftSide { $$=Util::createNList($1);};

rightList : reductionCall ',' val { $$=new tempNode();
	                                $$->reducCall=(reductionCall*)$1;
                                    $$->exprVal=(Expression*)$3; };
          | reductionCall { 
			                $$->reducCall=(reductionCall*)$1;} ;

reductionCall : reduction_op '(' arg_list ')' {$$=Util::createNodeforReductionCall($1,$3->AList);} ;

reduction_op : T_SUM { $$=REDUCE_SUM;};
	         | T_COUNT {$$=REDUCE_COUNT;};
	         | T_PRODUCT {$$=REDUCE_PRODUCT;};
	         | T_MAX {$$=REDUCE_MAX;};
	         | T_MIN {$$=REDUCE_MIN;};

leftSide : ID { $$=Util::createIdentifierNode($1);};
         | oid { $$=$1; };
         | tid {$$ = $1; };

arg_list :    {printf("No args\n");argument* a1=new argument();
		                // a1->expression=(Expression*)$1;
				//		 a1->expressionflag=true;
						  $$=Util::createAList(a1);};
						  
		|assignment ',' arg_list {printf("test3\n");argument* a1=new argument();
		                 a1->assignExpr=(assignment*)$3;
						  a1->assign=true;
						 $$=Util::addToAList($3,a1);printf("test4\n");
                                 };


	       |   expression ',' arg_list   {argument* a1=new argument();
		                                a1->expression=(Expression*)$3;
						               
										a1->expressionflag=true;
										 $$=Util::addToAList($3,a1);
						                };
	       | expression {argument* a1=new argument();
		                 a1->expression=(Expression*)$1;
						 a1->expressionflag=true;
						  $$=Util::createAList(a1); };
	       | assignment { printf("test1\n");argument* a1=new argument();
		                  a1->assignExpr=(assignment*)$1;
						  a1->assign=true;
						   $$=Util::createAList(a1);printf("test2\n");};


bfs_abstraction	: //T_BFS '(' ID ':' T_FROM ID ')' filterExpr blockstatements reverse_abstraction{$$=Util::createIterateInBFSNode($3,$6,$8,$9,$10) ;};
			| T_BFS '(' ID ':' T_FROM ID ')' filterExpr blockstatements {//$$=Util::createIterateInBFSNode($3,$6,$8,$9,$10) ;
			};



reverse_abstraction : T_REVERSE '(' boolean_expr ')' filterExpr blockstatements {$$=Util::createIterateInReverseBFSNode($3,$5,$6);};


oid : ID '.' ID { Identifier* id1=(Identifier*)Util::createIdentifierNode($1);
                   Identifier* id2=(Identifier*)Util::createIdentifierNode($1);
				   $$=Util::createPropIdNode(id1,id2);
				    };

tid : ID '.' ID '.' ID { Identifier* id1=(Identifier*)Util::createIdentifierNode($1);
                   Identifier* id2=(Identifier*)Util::createIdentifierNode($1);
				   $$=Util::createPropIdNode(id1,id2);
				    };

%%


void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}


int main(int argc,char **argv) {
	
  
   FILE    *fd;

    if (argc>1)
     yyin= fopen(argv[1],"r");
	else 
	  yyin=stdin;
	yyparse();

	return 0;   
	 
}