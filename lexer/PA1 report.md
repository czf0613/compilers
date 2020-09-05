# PA1 report

The basic idea to make the lexer is to apply the regular expression on codes to com.czf.project.test.generate tokens.

Basically, I divide tokens into four types, they are: operators(including keywords), identifiers(including variables and Type Identifiers), constants(including boolean, integer and string constants) and comments. 



## Part1

Operators and keywords are the most easiest part, the only thing you need to care about is just the escape and ignore the cases, for example, you cannot write down '+' since '+' has special meaning in regular expression. By the way, as the manual reference suggests, "Class" and "CLASS" and "claSs" and stuff like are also acceptable, so we need to add ""?i" before the regular expression.



## Part2

variable identifiers should start with a letter in lower case, like "integer", "big_integer" and stuff like that, so the regular expression is that 

```
[a-z][0-9a-zA-Z_]*
```

Similarly, Type identifiers is just like "String", "IO" which start with a letter in upper case, so the answer is 

```
[A-Z][0-9a-zA-Z_]*
```

But here is a tricky problem, since case of the keywords are ignored, so keywords like "Class", "True" could be recognized as a TYPE_ID or a keyword. To solve this question, I set up an agreement, the keyword has higher priority, so "Class" should be recognized as a keyword instead of a TYPE_ID, except "True" and "False" because they are treated as identifiers.



## Part3

Recognizing integers and boolean constants are very easy, just follow:

```
[0-9]+
t(?i:ure)
f(?i:alse)
```

But a string constant is a little bit complicated, we need to figure out some situations:

### 1, begin STRING status when reading an ' " ' in initial state

any string constant must start with "

### 2, pop an error when reading an EOF

that mean the string constant stop accidentally

### 3, care about the escape characters like \b \+ \" \' and stuff like that.

When it's presented in token string, (e.g) \n has already been escaped, so it is \\\n, we need to fix it.

### 4, pop an error when meeting a \n instead of \\\n

it's just the rule give by the cool language.

```
"This is \
OK"
"This is
not OK"
```

### 5, be careful of the length, should not be over 1025

Then comes the most difficult part, which is error handling, since the error occurred in the string constant would influence the analyze, so we need a strategy to skip the wrong part until we find a proper part to restart. Luckily, this part is not so difficult in lexer.



## Part4

dealing  with comment is much easier. In the single line comment, you just need to stop this status when reaching an \n. But we need to figure out the nesting comment.

I use a method that is called a counter. When meeting an (* , the depth of comment should +1, when meeting a *), the depth should -1, once the depth is back to zero, that means the nesting comment finished.

By the way, we have to solve the unmatched *), it's very easy because you just need to judge that the depth, if it's not zero, the *) is valid, when depth is zero, *) is invalid.



This is the brief report of the lexer, I didn't copy so much code because I think it will make a mess here, please consult the cool.flex file to see the exact implementation. Thank you.