/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int comment_level=0;
int str_len=0;
bool closed=false;

%}

DIGIT     [0-9]
NUMBER    {DIGIT}+
CAPITAL   [A-Z]
SMALL     [a-z]
CHAR      [a-zA-Z]
ALLCHAR   ({CHAR}|{DIGIT})
WHITE     [' '\f\r\t\v]
SPECIAL   ['\\''\"''\'''\b''\+''\-''\*''\/']
BAN       [\!\#\$\%\^\&\_\>\?\`\[\]\\\|]
BAD       ['\001''\002''\003''\004']

%x STRING
%x SINGLECOMMENT
%x COMMENT

%%

{WHITE} ;
"\n" {curr_lineno++;}

(?i:class) {return CLASS;}
(?i:else) {return ELSE;}
(?i:fi) {return FI;}
(?i:if) {return IF;}
(?i:in) {return IN;}
(?i:inherits) {return INHERITS;}
(?i:let) {return LET;}
(?i:loop) {return LOOP;}
(?i:pool) {return POOL;}
(?i:of) {return OF;}
(?i:while) {return WHILE;}
(?i:then) {return THEN;}
(?i:case) {return CASE;}
(?i:esac) {return ESAC;}
(?i:new) {return NEW;}
(t)(?i:rue) {
	cool_yylval.boolean=1;
	return BOOL_CONST;
}
(f)(?i:alse) { 
	cool_yylval.boolean=0;
	return BOOL_CONST;
}

(?i:not) {return NOT;}
(?i:isvoid) {return ISVOID;}
"+" {return int('+');}
"-" {return int('-');}
"*" {return int('*');}
"/" {return int('/');}
"." {return int('.');}
"@" {return int('@');}
"~" {return int('~');}
"<" {return int('<');}
"=" {return int('=');}
"=>" {return DARROW;}
"<-" {return ASSIGN;}
"<=" {return LE;}

"{" {return int('{');}
"}" {return int('}');}
"(" {return int('(');}
")" {return int(')');}
";" {return int(';');}
":" {return int(':');}
"," {return int(',');}	

{NUMBER} {
	cool_yylval.symbol=inttable.add_string(yytext);
	return INT_CONST;
}

{CAPITAL}({CHAR}|{DIGIT}|"_")* {
	cool_yylval.symbol=stringtable.add_string(yytext);
	return TYPEID;
}

({SMALL})({CHAR}|{DIGIT}|"_")* {
	cool_yylval.symbol=stringtable.add_string(yytext);
	return OBJECTID;
}

"--" BEGIN(SINGLECOMMENT);
<SINGLECOMMENT>([^\n])* ;
<SINGLECOMMENT>([\n]) {
	curr_lineno++;
	BEGIN(INITIAL);
}

"(*" {
	comment_level=1;
	BEGIN(COMMENT);
}
<COMMENT>([\n]) curr_lineno++;
<COMMENT>([^*()\n])* ;
<COMMENT>(\*) ;
<COMMENT>(\() ;
<COMMENT>(\)) ;
<COMMENT>"(*" comment_level++;
<COMMENT>"*)" {
	comment_level--;
	if(comment_level==0)
		BEGIN(INITIAL);
}
<COMMENT><<EOF>> {
	cool_yylval.error_msg="EOF in comment";
	BEGIN(INITIAL);
	return ERROR;
}

"\"" {
	string_buf_ptr=string_buf;
	str_len=0;
	closed=false;	
	BEGIN(STRING);
}
<STRING>([^\\\n\"\0])* {
	char* yptr=yytext;
	while(*yptr)
	{
		*string_buf_ptr++=*yptr++;
		str_len++;
	}
}
<STRING>([\0]) closed=true;
<STRING>(['\\'])({CHAR}|{DIGIT}|{SPECIAL}|{WHITE}) {
	str_len++;
	if(strcmp(yytext,"\\t")==0)
		*string_buf_ptr++='\t';
	else if(strcmp(yytext,"\\f")==0)
		*string_buf_ptr++='\f';
	else if(strcmp(yytext,"\\b")==0)
		*string_buf_ptr++='\b';
	else if(strcmp(yytext,"\\n")==0)
		*string_buf_ptr++='\n';
	else if(strcmp(yytext,"\\\"")==0)
		*string_buf_ptr++='\"';
	else if(strcmp(yytext,"\\\\")==0)
		*string_buf_ptr++='\\';
	else
	{
		char* yptr=yytext;
		yptr++;
		*string_buf_ptr++=*yptr++;
	}
}
<STRING>("\\\n") {
	curr_lineno++;
	*string_buf_ptr++='\n';
	str_len++;
}
<STRING>(['\"']) {
	if(closed)
	{
		cool_yylval.error_msg="String contains null character.";
		BEGIN(INITIAL);
		return ERROR;
	}
	*string_buf_ptr++='\0';
	cool_yylval.symbol=stringtable.add_string(string_buf);
	if(str_len>=MAX_STR_CONST)
	{
		cool_yylval.error_msg="String constant too long";
		BEGIN(INITIAL);
		return ERROR;
	}
	BEGIN(INITIAL);
	return STR_CONST;
}
<STRING>(['\n']) {
	cool_yylval.error_msg="Unterminated string constant";
	BEGIN(INITIAL);
	return ERROR;
}
<STRING>(['\\']) {
	cool_yylval.error_msg="String contains escaped null character.";
	BEGIN(INITIAL);
	return ERROR;
}
<STRING><<EOF>> {
	cool_yylval.error_msg="EOF in string constant";
	BEGIN(INITIAL);
	return ERROR;
}

"*)" {
	cool_yylval.error_msg="Unmatched *)";
	return ERROR;
}

({BAN}|{BAD}) {
	cool_yylval.error_msg=yytext;
	return ERROR;
}


%%
