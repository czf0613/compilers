# PA2 Parser

The basic idea of parser is to build the abstract syntax tree then you can apply the strategy to all the non-terminals. According to the reference manual of Cool Programming Language, it has only 5 non-terminals: program, class, feature, formal, expression.

But unfortunately, these 5 non-ternimals are not enough since there many be more classes or different kind of stuff, so I prepared other non-ternimals to fulfill the demands.

```
%type <program> program
%type <classes> class_list
%type <class_> class
%type <features> feature_list //the above is provided by default
%type <feature> feature
%type <feature> method
%type <feature> attribute
%type <formals> formal_list
%type <formal> formal
%type <cases> branch_list
%type <case_> branch
%type <expression> let_expression
%type <expression> static_dispatch_expression
%type <expression> dispatch_expression
%type <expression> expression
%type <expressions> multi_expression
%type <expressions> expression_list
```

 I will discuss later about those kinds of expressions. Before we go to analyze, we should follow some rules, that is, the precedences and associativities. Just follow the instructions in PPT, we know that, except the ASSIGN and "< = <=", other stuff can be treated as left associativity, "< = <=" can not be associative since the two operands can not change their order. Also, the lines are listed in order of increasing precedence, so the rules are as follows.

```
%right ASSIGN
%left NOT
%nonassoc '<' '=' LE
%left '+' '-'
%left '*' '/'
%left ISVOID
%left '~'
%left '@'
%left '.'
```



There are two com.czf.project.test.main parts in parser, the first part is, dealing with non-terminals, dealing with terminals. Then we need to solve the hierarchy of parser, I split it into several rules:

### 1, program is made up by several classes

### 2, class could inherit from 1 or more classes or not. 

In case of multi-inheritance, so we should use class_list(single class is included in this case since the class_list contains only one class)

### 3, class has its attributes, and member functions

these two types are all included in "features", to avoid mess, I split them into feature, method, attribute.

### 4, identifiers and types are needed in declaration

These are the formals

### 5, deal with branches like if-else

### 6, expressions has many types

#### let expressions

#### "static_dispatch_expression" means those function start with @

#### "dispatch_expression" means invoking the member function

#### "multi_expression" means multi-expressions in one sentence

like this in java, a is a string, then you invoke: a.substring(0, 5).substring(0, 2)

### 7, deal with terminals



The bison script is very complicated so I just show part of it to show my thinking. It's just similar to deal with other cases

## 1, dealing with classes

```
class_list: class
    {
        $$ = single_Classes($1);
        parse_results = $$;
    }

    | class_list class
    {
        $$ = append_Classes($1,single_Classes($2));
        parse_results = $$;
    }
;

class: CLASS TYPEID '{' feature_list '}' ';'
    {
        $$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename));
    }

    | CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
    {
        $$ = class_($2, $4, $6, stringtable.add_string(curr_filename));
    }

    | error ';'
    { /* error recovery */ }
;

/*Actually, I find the dummy feature list is not nessessary, so I remove it*/
feature_list: /* epsilon */
    {	$$ = nil_Features();	}

    | feature
    {	$$ = single_Features($1);	}

    | feature_list feature
    {	$$ = append_Features($1, single_Features($2));	}
;

method: OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' ';'
    {	$$ = method($1, $3, $6, $8);	}

    | OBJECTID '(' ')' ':' TYPEID '{' expression '}' ';'
    {	$$ = method($1, nil_Formals(), $5, $7); }
;

attribute: OBJECTID ':' TYPEID ASSIGN expression ';'
    {	$$ = attr($1, $3, $5);	}

    | OBJECTID ':' TYPEID ';'
    {	$$ = attr($1, $3, no_expr());	}
;

feature: method
    {	$$ = $1;	}

    | attribute
    {	$$ = $1;	}

    | error ';'
    { /* error recovery */ }
;
```

## 2, deal with terminals(just part of the expressions)

```
    | expression '+' expression
    {   $$ = plus($1, $3);  }

    | expression '-' expression
    {   $$ = sub($1, $3);   }

    | expression '*' expression
    {   $$ = mul($1, $3);   }

    | expression '/' expression
    {   $$ = divide($1, $3);    }

    | '~' expression
    {   $$ = neg($2);   }

    | expression '<' expression
    {   $$ = lt($1, $3);    }

    | expression LE expression
    {   $$ = leq($1, $3);   }

    | expression '=' expression
    {   $$ = eq($1, $3);    }

    | NOT expression
    {   $$ = comp($2);  }

    | '(' expression ')'
    {   $$ = $2;    }

    | OBJECTID
    {   $$ = object($1);    }

    | INT_CONST
    {   $$ = int_const($1); }

    | STR_CONST
    {   $$ = string_const($1);  }

    | BOOL_CONST
    {   $$ = bool_const($1);    }
```



I think it's hard to show how I implement my thinking so I just paste some of the codes to let you know how I understand the hierarchy.