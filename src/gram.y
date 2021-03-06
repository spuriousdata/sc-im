%{
#include <curses.h>
#include <stdlib.h>
#include "sc.h"
#include "cmds.h"
#include "color.h"
#include "interp.h"
#include "macros.h"
#include "sort.h"
#include "filter.h"
#include "maps.h"
#include "marks.h"
#include "xmalloc.h" // for scxfree
#include "hide_show.h"
#include "cmds_normal.h"
#include "conf.h"
#include "pipe.h"
#include "main.h"
#include "screen.h"
#include "undo.h"
#include "dep_graph.h"

void yyerror(char *err);               // error routine for yacc (gram.y)
int yylex();


#ifdef USELOCALE
#include <locale.h>
#endif

#ifndef MSDOS
#include <unistd.h>
#endif

#define ENULL (struct enode *) 0
%}

%union {
    int ival;
    double fval;
    struct ent_ptr ent;
    struct enode * enode;
    char * sval;
    struct range_s rval; // no debiera usarse en futuro
}

%type <ent> var
%type <fval> num
%type <rval> range
%type <rval> var_or_range
%type <sval> strarg
%type <enode> e term expr_list
%token <sval> STRING
%token <ival> COL
%token <ival> NUMBER
%token <fval> FNUMBER
%token <rval> RANGE

%token <rval> VAR
%token <sval> WORD
%token <sval> MAPWORD
%token <sval> PLUGIN

/*
 *  When adding new commands, make sure that any commands that may take
 *  COL as an argument precede S_FORMAT in the %token list.  All other
 *  commands must come after S_FORMAT.  This is necessary so that range
 *  names can be less than three letters without being parsed as column
 *  names.
 */

%token S_SHOW
%token S_HIDE
%token S_SHOWROW
%token S_HIDEROW
%token S_SHOWCOL
%token S_HIDECOL
%token S_MARK
%token S_AUTOJUS
%token S_PAD

/*
token <ival> CARACTER
token S_INSERTCOL
token S_OPENCOL
token S_DELETECOL
token S_YANKCOL
*/

%token S_DATEFMT
%token S_FORMAT
%token S_FMT
%token S_LET
%token S_LABEL
%token S_LEFTSTRING
%token S_RIGHTSTRING
%token S_LEFTJUSTIFY
%token S_RIGHTJUSTIFY
%token S_CENTER
%token S_SORT
%token S_FILTERON
%token S_GOTO
%token S_SET
%token S_LOCK
%token S_UNLOCK
%token S_DEFINE
%token S_UNDEFINE
%token S_EVAL
%token S_SEVAL

/*
 token S_ADDNOTE
 token S_DELNOTE
 token S_GET
 token S_PUT
 token S_MERGE
 token S_WRITE
 token S_TBL
 token S_COPY
 token S_MOVE
 token S_ERASE
 token S_YANK
 token S_FILL
 token S_ABBREV
 token S_UNABBREV
 token S_FRAME
 token S_FRAMETOP
 token S_FRAMEBOTTOM
 token S_FRAMELEFT
 token S_FRAMERIGHT
 token S_UNFRAME
 token S_VALUE
 token S_MDIR
 token S_AUTORUN
 token S_FKEY
 token S_SCEXT
 token S_ASCEXT
 token S_TBL0EXT
 token S_TBLEXT
 token S_LATEXEXT
 token S_SLATEXEXT
 token S_TEXEXT
 token S_UP
 token S_DOWN
 token S_LEFT
 token S_RIGHT
 token S_ENDUP
 token S_ENDDOWN
 token S_ENDLEFT
 token S_ENDRIGHT
 token S_SELECT
 token S_INSERTROW
 token S_OPENROW
 token S_DELETEROW
 token S_YANKROW
 token S_PULL
 token S_PULLMERGE
 token S_PULLROWS
 token S_PULLCOLS
 token S_PULLXCHG
 token S_PULLTP
 token S_PULLFMT
 token S_PULLCOPY
 token S_WHEREAMI
 token S_FGETNUM
 token S_GETFRAME
 token S_GETRANGE
 token S_QUERY
 token S_GETKEY
 token S_ERROR
 token S_REDRAW
 token S_STATUS
 token S_RUN
 token S_PLUGIN
 token S_PLUGOUT
*/

%token S_GETNUM
%token S_GETSTRING
%token S_GETEXP
%token S_GETFMT
%token S_GETFORMAT
%token S_RECALC
%token S_QUIT
%token S_REBUILD_GRAPH
%token S_PRINT_GRAPH
%token S_SYNCREFS
%token S_REDO
%token S_UNDO
%token S_IMAP
%token S_NMAP
%token S_INOREMAP
%token S_NNOREMAP
%token S_NUNMAP
%token S_IUNMAP
%token S_COLOR
%token S_CELLCOLOR
%token S_REDEFINE_COLOR

%token K_ERROR
%token K_INVALID
%token K_FIXED
%token K_SUM
%token K_PROD
%token K_AVG
%token K_STDDEV
%token K_COUNT
%token K_ROWS
%token K_COLS
%token K_ABS
%token K_ACOS
%token K_ASIN
%token K_ATAN
%token K_ATAN2
%token K_CEIL
%token K_COS
%token K_EXP
%token K_FABS
%token K_FLOOR
%token K_HYPOT
%token K_LN
%token K_LOG
%token K_PI
%token K_POW
%token K_SIN
%token K_SQRT
%token K_TAN
%token K_DTR
%token K_RTD
%token K_MAX
%token K_MIN
%token K_RND
%token K_ROUND
%token K_IF
%token K_PV
%token K_FV
%token K_PMT
%token K_HOUR
%token K_MINUTE
%token K_SECOND
%token K_MONTH
%token K_DAY
%token K_YEAR
%token K_NOW
%token K_DATE
%token K_DTS
%token K_TTS
%token K_FMT
%token K_SUBSTR
%token K_UPPER
%token K_LOWER
%token K_CAPITAL
%token K_STON
%token K_SLEN
%token K_EQS
%token K_EXT
%token K_NVAL
%token K_SVAL
%token K_LOOKUP
%token K_HLOOKUP
%token K_VLOOKUP
%token K_INDEX
%token K_STINDEX
%token K_AUTO
%token K_AUTOCALC
%token K_AUTOINSERT
%token K_AUTOWRAP
%token K_CSLOP
%token K_BYROWS
%token K_BYCOLS
%token K_OPTIMIZE
%token K_ITERATIONS
%token K_NUMERIC
%token K_PRESCALE
%token K_EXTFUN
%token K_CELLCUR
%token K_TOPROW
%token K_COLOR
%token K_COLORNEG
%token K_COLORERR
%token K_BRAILLE
/*
token K_BLACK
token K_RED
token K_GREEN
token K_YELLOW
token K_BLUE
token K_MAGENTA
token K_CYAN
token K_WHITE
*/
%token K_TBLSTYLE
%token K_TBL
%token K_LATEX
%token K_SLATEX
%token K_TEX
%token K_FRAME
%token K_RNDTOEVEN
%token K_FILENAME
%token K_MYROW
%token K_MYCOL
%token K_LASTROW
%token K_LASTCOL
%token K_COLTOA
%token K_CRACTION
%token K_CRROW
%token K_CRCOL
%token K_ROWLIMIT
%token K_COLLIMIT
%token K_PAGESIZE
/*
 token K_NUMITER
*/
%token K_ERR
%token K_LOCALE
%token K_SET8BIT
%token K_ASCII
%token K_CHR

%right ';'
%left '?' ':'
%left '|'
%left '&'
%nonassoc '<' '=' '>' '!'
%left '+' '-' '#'
%left '*' '/' '%'
%left '^'

%%
command:
         S_LET var_or_range '=' e { let($2.left.vp, $4);
                                    //sc_debug("!! %d %d %d %d", $2.left.vp->row, $2.left.vp->col);
                                    //if ($4->e.v.vp != NULL) {
                                    //    sc_debug("!!! %d %d - %d %d", $2.left.vp->row, $2.left.vp->col, $4->e.v.vp->row, $4->e.v.vp->col);
                                  }
    |    S_LET var_or_range '='
                                  { $2.left.vp->v = (double) 0.0;
                                  if ($2.left.vp->expr && !($2.left.vp->flags & is_strexpr)) {
                                    efree($2.left.vp->expr);
                                    $2.left.vp->expr = NULL;
                                  }
                                  $2.left.vp->cellerror = CELLOK;
                                  $2.left.vp->flags &= ~is_valid;
                                  $2.left.vp->flags |= is_changed;
                                  changed++;
                                  modflg++;
                                  }

    |    S_LABEL var_or_range '=' e       { slet($2.left.vp, $4, 0); }
    |    S_LEFTSTRING var_or_range '=' e  { slet($2.left.vp, $4, -1); }
    |    S_RIGHTSTRING var_or_range '=' e { slet($2.left.vp, $4, 1); }



    |    S_LEFTJUSTIFY var_or_range  { ljustify($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col); }
    |    S_RIGHTJUSTIFY var_or_range { rjustify($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col); }
    |    S_CENTER var_or_range       { center($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col); }
    |    S_FORMAT COL NUMBER NUMBER NUMBER { doformat($2,$2,$3,$4,$5); }
    |    S_FMT var_or_range STRING   { format_cell($2.left.vp, $2.right.vp, $3);
                                       scxfree($3);
                                     }

    |    S_DATEFMT var_or_range STRING { dateformat($2.left.vp, $2.right.vp, $3);
                                       scxfree($3); }
    |    S_DATEFMT STRING            { dateformat(lookat(currow, curcol), lookat(currow, curcol), $2);
                                       scxfree($2); }
/* para compatibilidad con sc */
    |    S_HIDE COL                  { hide_col($2, 1); }        // hide de una unica columna
    |    S_HIDE NUMBER               { hide_row($2, 1); }        // hide de una unica fila
    |    S_SHOW COL                  { show_col($2, 1); }        // show de una unica columna
    |    S_SHOW NUMBER               { show_row($2, 1); }        // show de una unica fila

/* agregados para scim */
    |    S_HIDECOL COL               {
                                       hide_col($2, 1); }        // hide de una unica columna
    |    S_SHOWCOL COL               {
                                       show_col($2, 1); }        // show de una unica columna
    |    S_HIDEROW NUMBER            {
                                       hide_row($2, 1); }        // hide de una unica fila
    |    S_SHOWROW NUMBER            {
                                       show_row($2, 1); }        // show de una unica fila
    |    S_SHOWCOL COL ':' COL       {
                                       show_col($2, $4-$2+1); }  // show de un rango de columnas
    |    S_SHOWROW NUMBER ':' NUMBER {
                                       show_row($2, $4-$2+1); }  // show de un rango de filas
    |    S_HIDECOL COL ':' COL       {
                                       int c = curcol, arg;
                                       if ($2 < $4) {
                                            curcol = $2;
                                            arg = $4 - $2 + 1;
                                       } else {
                                            curcol = $4;
                                            arg = $2 - $4 + 1;
                                       }
                                       hide_col($2, arg);        // hide de un rango de columnas
                                       curcol = c < curcol ? c : c < curcol + arg ? curcol : c - arg;
                                     }
    |    S_HIDEROW NUMBER ':' NUMBER {
                                       int r = currow, arg;      // hide de un rango de filas
                                       if ($2 < $4) {
                                           currow = $2;
                                           arg = $4 - $2 + 1;
                                       } else {
                                           currow = $4;
                                           arg = $2 - $4 + 1;
                                       }
                                       hide_row($2, arg);
                                       currow = r < currow ? r : r < currow + arg ? currow : r - arg;
                                     }

    |    S_MARK COL var_or_range     { set_cell_mark($2 + 97, $3.left.vp->row, $3.left.vp->col); }

    |    S_MARK COL var_or_range var_or_range { ;
                                          srange * sr = create_range('\0', '\0', $3.left.vp, $4.left.vp);
                                          unselect_ranges();
                                          set_range_mark($2 + 97, sr);
                                          }

    |    S_SORT range STRING         { sortrange($2.left.vp, $2.right.vp, $3);
                                          //scxfree($3);
                                     }
    |    S_FILTERON range            { enable_filters($2.left.vp, $2.right.vp);
                                     }
                                          /* para debug
                                          wtimeout(input_win, -1);
                                          info("  ********* FILTERON");
                                          int d = wgetch(input_win);
                                          wtimeout(input_win, TIMEOUT_CURSES);
                                          */
/*
    |    S_GET strarg {
/* This tmp hack is because readfile recurses back through yyparse.
                    char *tmp;
                    tmp = $2;
                    readfile(tmp, 1);
                    scxfree(tmp);
                }
*/
    |    S_AUTOJUS COL ':' COL       { auto_justify($2, $4, DEFWIDTH); }  // auto justificado de columnas
    |    S_AUTOJUS COL               { auto_justify($2, $2, DEFWIDTH); }  // auto justificado de columna

    |    S_GOTO var_or_range var_or_range { moveto($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, $3.left.vp->row, $3.left.vp->col); }
    |    S_GOTO var_or_range     { moveto($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, -1, -1); }
    |    S_GOTO num              { num_search($2, 0, 0, maxrow, maxcol, 0, 1); }
    |    S_GOTO STRING           { str_search($2, 0, 0, maxrow, maxcol, 0, 1);
                                   scxfree($2); }
    |    S_GOTO '#' STRING       { str_search($3, 0, 0, maxrow, maxcol, 1, 1);
                                   scxfree($3); }
    |    S_GOTO '%' STRING       { str_search($3, 0, 0, maxrow, maxcol, 2, 1);
                                   scxfree($3); }
    |    S_GOTO WORD             { /* don't repeat last goto on "unintelligible word" */ ; }

    |    S_LOCK var_or_range     { lock_cells($2.left.vp, $2.right.vp); }
    |    S_UNLOCK var_or_range   { unlock_cells($2.left.vp, $2.right.vp); }
    |    S_NMAP STRING STRING           {
                                          add_map($2, $3, NORMAL_MODE, 1);
                                          scxfree($2);
                                          scxfree($3);
                                        }

    |    S_IMAP STRING STRING
                                        {
                                          add_map($2, $3, INSERT_MODE, 1);
                                          scxfree($2);
                                          scxfree($3);
                                        }
    |    S_NNOREMAP STRING STRING       {
                                          add_map($2, $3, NORMAL_MODE, 0);
                                          scxfree($2);
                                          scxfree($3);
                                        }

    |    S_INOREMAP STRING STRING       {
                                          add_map($2, $3, INSERT_MODE, 0);
                                          scxfree($2);
                                          scxfree($3);
                                        }


    |    S_NUNMAP STRING                {
                                          del_map($2, NORMAL_MODE);
                                          scxfree($2);
                                        }

    |    S_IUNMAP STRING                {
                                          del_map($2, INSERT_MODE);
                                          scxfree($2);
                                        }

    |    S_COLOR STRING                 {
#ifdef USECOLORS
                                          chg_color($2);
#endif
                                          scxfree($2);
                                        }

    |    S_CELLCOLOR var_or_range STRING {
#ifdef USECOLORS
                                          if ( ! atoi(get_conf_value("nocurses")))
                                              color_cell($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, $3);
#endif
                                          scxfree($3);
                                        }

    |    S_REDEFINE_COLOR STRING NUMBER NUMBER NUMBER {
                                         redefine_color($2, $3, $4, $5);
                                         scxfree($2); }

    |    S_PAD NUMBER COL ':' COL    { pad($2, 0, $3, maxrow, $5); }
    |    S_PAD NUMBER COL            { pad($2, 0, $3, maxrow, $3); }
    |    S_PAD NUMBER var_or_range   { pad($2, $3.left.vp->row, $3.left.vp->col, $3.right.vp->row, $3.right.vp->col); }

/*
    |    S_DEFINE strarg                { struct ent_ptr arg1, arg2;
                                          arg1.vp = lookat(showsr, showsc);
                                          arg1.vf = 0;
                                          arg2.vp = lookat(currow, curcol);
                                          arg2.vf = 0;
                                          if (arg1.vp == arg2.vp )
                                              add_range($2, arg2, arg2, 0);
                                          else
                                              add_range($2, arg1, arg2, 1);
                                        }
*/
    |    S_DEFINE strarg range      { add_range($2, $3.left, $3.right, 1); }
    |    S_DEFINE strarg var        { add_range($2, $3, $3, 0); }
/*    |    S_DEFINE strarg NUMBER     { info("%s %d", $2, $3); get_key(); } */
    |    S_UNDEFINE var_or_range    { del_range($2.left.vp, $2.right.vp); }

    |    S_EVAL e                   { eval_result = eval(NULL, $2);
                                      efree($2);
                                    }
    |    S_QUIT                     { printf("quitting. unsaved changes will be lost.\n");
                                      shall_quit = 2; // unsaved changes are lost!
                                    }
    |    S_REBUILD_GRAPH            { rebuild_graph();
                                      update(FALSE);
                                    }

    |    S_PRINT_GRAPH              { print_vertexs(); }
    |    S_SYNCREFS                 { sync_refs(); }
    |    S_UNDO                     {
                                      do_undo();
                                      // sync_refs();
                                      EvalAll();
                                      update(TRUE);
                                    }

    |    S_REDO                     {
                                      do_redo();
                                      // sync_refs();
                                      EvalAll();
                                      update(TRUE);
                                    }


// For scripting and piping

    |    S_RECALC                   {
                                      EvalAll();
                                      //update(1);
                                      //changed = 0;
                                    }
    |    S_GETNUM var_or_range      {
                                      getnum($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, fdoutput);
                                    }

    |    S_GETSTRING var_or_range   { getstring($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, fdoutput); }

    |    S_GETEXP var_or_range      { getexp($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, fdoutput); }

    |    S_GETFORMAT COL            { getformat($2, fdoutput); }

    |    S_GETFMT var_or_range      { getfmt($2.left.vp->row, $2.left.vp->col, $2.right.vp->row, $2.right.vp->col, fdoutput); }

    |    S_SEVAL e                  { seval_result = seval(NULL, $2); // TODO make sure this seval_result is always freed afterwards
                                      efree($2);
                                    }
/*
    |    S_ERROR STRING        { error($2); }

    |    S_REDRAW        { if (usecurses) {
                        clearok(stdscr, TRUE);
                        linelim = -1;
                        update(1);
                        refresh();
                        changed = 0;
                      }
                    }

    |    S_RUN STRING        { //deraw(1);
                      system($2);
                      if (*($2 + strlen($2) - 1) != '&') {
                        printf("Press any key to continue ");
                        fflush(stdout);
                        cbreak();
                        get_key();
                      }
                      //goraw();
                      scxfree($2); }



    |    S_PLUGIN STRING '=' STRING
                    { addplugin($2, $4, 'r'); }
    |    S_PLUGOUT STRING '=' STRING
                    { addplugin($2, $4, 'w'); }
    |    PLUGIN            { *line = '|';
                      sprintf(line + 1, $1);
                      readfile(line, 0);
                      scxfree($1); }

*/
    |    // nothing
    |    error;
term:           var                     { $$ = new_var(O_VAR, $1); }
        |       '@' K_FIXED term        { $$ = new('f', $3, ENULL); }
        |       '(' '@' K_FIXED ')' term
                                        { $$ = new('F', $5, ENULL); }
        |       '@' K_SUM '(' var_or_range ')'
                                { $$ = new(SUM,
                                        new_range(REDUCE | SUM, $4), ENULL); }
        |       '@' K_SUM  '(' range ',' e ')'
                                { $$ = new(SUM,
                                        new_range(REDUCE | SUM, $4), $6); }
        |       '@' K_PROD '(' var_or_range ')'
                                { $$ = new(PROD,
                                        new_range(REDUCE | PROD, $4), ENULL); }
        |       '@' K_PROD  '(' range ',' e ')'
                                { $$ = new(PROD,
                                        new_range(REDUCE | PROD, $4), $6); }
        |       '@' K_AVG '(' var_or_range ')'
                                { $$ = new(AVG,
                                        new_range(REDUCE | AVG, $4), ENULL); }
        |       '@' K_AVG  '(' range ',' e ')'
                                { $$ = new(AVG,
                                        new_range(REDUCE | AVG, $4), $6); }
        |       '@' K_STDDEV '(' var_or_range ')'
                                { $$ = new(STDDEV,
                                        new_range(REDUCE | STDDEV, $4), ENULL); }
        |       '@' K_STDDEV  '(' range ',' e ')'
                                { $$ = new(STDDEV,
                                        new_range(REDUCE | STDDEV, $4), $6); }
        |       '@' K_COUNT '(' var_or_range ')'
                                { $$ = new(COUNT,
                                        new_range(REDUCE | COUNT, $4), ENULL); }
        |       '@' K_COUNT  '(' range ',' e ')'
                                { $$ = new(COUNT,
                                        new_range(REDUCE | COUNT, $4), $6); }
        |       '@' K_MAX '(' var_or_range ')'
                                { $$ = new(MAX,
                                        new_range(REDUCE | MAX, $4), ENULL); }
        |       '@' K_MAX  '(' range ',' e ')'
                                { $$ = new(MAX,
                                        new_range(REDUCE | MAX, $4), $6); }
        |       '@' K_MAX '(' e ',' expr_list ')'
                                { $$ = new(LMAX, $6, $4); }
        |       '@' K_MIN '(' var_or_range ')'
                                { $$ = new(MIN,
                                        new_range(REDUCE | MIN, $4), ENULL); }
        |       '@' K_MIN  '(' range ',' e ')'
                                { $$ = new(MIN,
                                        new_range(REDUCE | MIN, $4), $6); }
        |       '@' K_MIN '(' e ',' expr_list ')'
                                { $$ = new(LMIN, $6, $4); }
        |       '@' K_ROWS '(' var_or_range ')'
                                { $$ = new_range(REDUCE | 'R', $4); }
        |       '@' K_COLS '(' var_or_range ')'
                                { $$ = new_range(REDUCE | 'C', $4); }
        | '@' K_ABS '(' e ')'           { $$ = new(ABS, $4, ENULL); }
        | '@' K_ACOS '(' e ')'          { $$ = new(ACOS, $4, ENULL); }
        | '@' K_ASIN '(' e ')'          { $$ = new(ASIN, $4, ENULL); }
        | '@' K_ATAN '(' e ')'          { $$ = new(ATAN, $4, ENULL); }
        | '@' K_ATAN2 '(' e ',' e ')'   { $$ = new(ATAN2, $4, $6); }
        | '@' K_CEIL '(' e ')'          { $$ = new(CEIL, $4, ENULL); }
        | '@' K_COS '(' e ')'           { $$ = new(COS, $4, ENULL); }
        | '@' K_EXP '(' e ')'           { $$ = new(EXP, $4, ENULL); }
        | '@' K_FABS '(' e ')'          { $$ = new(FABS, $4, ENULL); }
        | '@' K_FLOOR '(' e ')'         { $$ = new(FLOOR, $4, ENULL); }
        | '@' K_HYPOT '(' e ',' e ')'   { $$ = new(HYPOT, $4, $6); }
        | '@' K_LN '(' e ')'            { $$ = new(LOG, $4, ENULL); }
        | '@' K_LOG '(' e ')'           { $$ = new(LOG10, $4, ENULL); }
        | '@' K_POW '(' e ',' e ')'     { $$ = new(POW, $4, $6); }
        | '@' K_SIN '(' e ')'           { $$ = new(SIN, $4, ENULL); }
        | '@' K_SQRT '(' e ')'          { $$ = new(SQRT, $4, ENULL); }
        | '@' K_TAN '(' e ')'           { $$ = new(TAN, $4, ENULL); }
        | '@' K_DTR '(' e ')'           { $$ = new(DTR, $4, ENULL); }
        | '@' K_RTD '(' e ')'           { $$ = new(RTD, $4, ENULL); }
        | '@' K_RND '(' e ')'           { $$ = new(RND, $4, ENULL); }
        | '@' K_ROUND '(' e ',' e ')'   { $$ = new(ROUND, $4, $6); }
        | '@' K_IF  '(' e ',' e ',' e ')' { $$ = new(IF,  $4,new(',',$6,$8)); }

        | '@' K_PV  '(' e ',' e ',' e ')' { $$ = new(PV,  $4,new(':',$6,$8)); }
        | '@' K_FV  '(' e ',' e ',' e ')' { $$ = new(FV,  $4,new(':',$6,$8)); }
        | '@' K_PMT '(' e ',' e ',' e ')' { $$ = new(PMT, $4,new(':',$6,$8)); }

        | '@' K_HOUR '(' e ')'          { $$ = new(HOUR, $4, ENULL); }
        | '@' K_MINUTE '(' e ')'        { $$ = new(MINUTE, $4, ENULL); }
        | '@' K_SECOND '(' e ')'        { $$ = new(SECOND, $4, ENULL); }
        | '@' K_MONTH '(' e ')'         { $$ = new(MONTH, $4, ENULL); }
        | '@' K_DAY '(' e ')'           { $$ = new(DAY, $4, ENULL); }
        | '@' K_YEAR '(' e ')'          { $$ = new(YEAR, $4, ENULL); }
        | '@' K_NOW                     { $$ = new(NOW, ENULL, ENULL);}
        | '@' K_DTS '(' e ',' e ',' e ')'
                                        { $$ = new(DTS, $4, new(',', $6, $8));}
        | NUMBER '.' NUMBER '.' NUMBER  { $$ = new(DTS,
                                new_const(O_CONST, (double) $1),
                                new(',', new_const(O_CONST, (double) $3),
                                new_const(O_CONST, (double) $5)));}
        | '@' K_TTS '(' e ',' e ',' e ')'
                                        { $$ = new(TTS, $4, new(',', $6, $8));}
        | '@' K_STON '(' e ')'          { $$ = new(STON, $4, ENULL); }
        | '@' K_SLEN '(' e ')'          { $$ = new(SLEN, $4, ENULL); }
        | '@' K_EQS '(' e ',' e ')'     { $$ = new(EQS, $4, $6); }
        | '@' K_DATE '(' e ')'          { $$ = new(DATE, $4, ENULL); }
        | '@' K_DATE '(' e ',' e ')'    { $$ = new(DATE, $4, $6); }
        | '@' K_FMT  '(' e ',' e ')'    { $$ = new(FMT, $4, $6); }
        | '@' K_UPPER '(' e ')'         { $$ = new(UPPER, $4, ENULL); }
        | '@' K_LOWER '(' e ')'         { $$ = new(LOWER, $4, ENULL); }
        | '@' K_CAPITAL '(' e ')'       { $$ = new(CAPITAL, $4, ENULL); }
        | '@' K_INDEX  '(' range ',' e ')'
                 { $$ = new(INDEX, new_range(REDUCE | INDEX, $4), $6); }
        | '@' K_INDEX  '(' e ',' range ')'
                 { $$ = new(INDEX, new_range(REDUCE | INDEX, $6), $4); }
        | '@' K_INDEX  '(' range ',' e ',' e ')'
                 { $$ = new(INDEX, new_range(REDUCE | INDEX, $4),
                    new(',', $6, $8)); }
        | '@' K_LOOKUP  '(' range ',' e ')'
                 { $$ = new(LOOKUP, new_range(REDUCE | LOOKUP, $4), $6); }
        | '@' K_LOOKUP  '(' e ',' range ')'
                 { $$ = new(LOOKUP, new_range(REDUCE | LOOKUP, $6), $4); }
        | '@' K_HLOOKUP  '(' range ',' e ',' e ')'
                 { $$ = new(HLOOKUP, new_range(REDUCE | HLOOKUP, $4),
                    new(',', $6, $8)); }
        | '@' K_HLOOKUP  '(' e ',' range ',' e ')'
                 { $$ = new(HLOOKUP, new_range(REDUCE | HLOOKUP, $6),
                    new(',', $4, $8)); }
        | '@' K_VLOOKUP  '(' range ',' e ',' e ')'
                 { $$ = new(VLOOKUP, new_range(REDUCE | VLOOKUP, $4),
                    new(',', $6, $8)); }
        | '@' K_VLOOKUP  '(' e ',' range ',' e ')'
                 { $$ = new(VLOOKUP, new_range(REDUCE | VLOOKUP, $6),
                    new(',', $4, $8)); }
        | '@' K_STINDEX  '(' range ',' e ')'
                 { $$ = new(STINDEX, new_range(REDUCE | STINDEX, $4), $6); }
        | '@' K_STINDEX  '(' e ',' range ')'
                 { $$ = new(STINDEX, new_range(REDUCE | STINDEX, $6), $4); }
        | '@' K_STINDEX  '(' range ',' e ',' e ')'
                 { $$ = new(STINDEX, new_range(REDUCE | STINDEX, $4),
                    new(',', $6, $8)); }
        | '@' K_EXT  '(' e ',' e ')'    { $$ = new(EXT, $4, $6); }
        | '@' K_NVAL '(' e ',' e ')'    { $$ = new(NVAL, $4, $6); }
        | '@' K_SVAL '(' e ',' e ')'    { $$ = new(SVAL, $4, $6); }
        | '@' K_SUBSTR '(' e ',' e ',' e ')'
                                { $$ = new(SUBSTR, $4, new(',', $6, $8)); }
        |       '(' e ')'       { $$ = $2; }
        |       '+' term        { $$ = $2; }
        |       '-' term        { $$ = new('m', $2, ENULL); }
        |       NUMBER          { $$ = new_const(O_CONST, (double) $1); }
        |       FNUMBER         { $$ = new_const(O_CONST, $1); }
        | '@'   K_PI            { $$ = new(PI_, ENULL, ENULL); }
        |       STRING          { $$ = new_str($1); }
        |       '~' term        { $$ = new('!', $2, ENULL); }
        |       '!' term        { $$ = new('!', $2, ENULL); }
        | '@' K_FILENAME '(' e ')'      { $$ = new(FILENAME, $4, ENULL); }
        | '@' K_MYROW                   { $$ = new(MYROW, ENULL, ENULL);}
        | '@' K_MYCOL                   { $$ = new(MYCOL, ENULL, ENULL);}
        | '@' K_LASTROW                 { $$ = new(LASTROW, ENULL, ENULL);}
        | '@' K_LASTCOL                 { $$ = new(LASTCOL, ENULL, ENULL);}
        | '@' K_COLTOA '(' e ')'        { $$ = new(COLTOA, $4, ENULL);}
        | '@' K_ASCII '(' e ')'         { $$ = new(ASCII, $4, ENULL); }
        | '@' K_SET8BIT '(' e ')'       { $$ = new(SET8BIT, $4, ENULL); }
        | '@' K_CHR '(' e ')'           { $$ = new(CHR, $4, ENULL);}
        | '@' K_ERR             { $$ = new(ERR_, ENULL, ENULL); }
        |     K_ERR             { $$ = new(ERR_, ENULL, ENULL); }
/*
        | '@' K_NUMITER                 { $$ = new(NUMITER, ENULL, ENULL);}
        | '@' K_BLACK           { $$ = new(BLACK, ENULL, ENULL); }
        | '@' K_RED             { $$ = new(RED, ENULL, ENULL); }
        | '@' K_GREEN           { $$ = new(GREEN, ENULL, ENULL); }
        | '@' K_YELLOW          { $$ = new(YELLOW, ENULL, ENULL); }
        | '@' K_BLUE            { $$ = new(BLUE, ENULL, ENULL); }
        | '@' K_MAGENTA         { $$ = new(MAGENTA, ENULL, ENULL); }
        | '@' K_CYAN            { $$ = new(CYAN, ENULL, ENULL); }
        | '@' K_WHITE           { $$ = new(WHITE, ENULL, ENULL); }
*/
        ;

/* expressions */
e:       e '+' e        { $$ = new('+', $1, $3); }
    |    e '-' e        { $$ = new('-', $1, $3); }
    |    e '*' e        { $$ = new('*', $1, $3); }
    |    e '/' e        { $$ = new('/', $1, $3); }
    |    e '%' e        { $$ = new('%', $1, $3); }
    |    e '^' e        { $$ = new('^', $1, $3); }
    |    term
    |    e '?' e ':' e    { $$ = new('?', $1, new(':', $3, $5)); }
    |    e ';' e        { $$ = new(';', $1, $3); }
    |    e '<' e        { $$ = new('<', $1, $3); }
    |    e '=' e        { $$ = new('=', $1, $3); }
    |    e '>' e        { $$ = new('>', $1, $3); }
    |    e '&' e        { $$ = new('&', $1, $3); }
    |    e '|' e        { $$ = new('|', $1, $3); }
    |    e '<' '=' e    { $$ = new('!', new('>', $1, $4), ENULL); }
    |    e '!' '=' e    { $$ = new('!', new('=', $1, $4), ENULL); }
    |    e '<' '>' e    { $$ = new('!', new('=', $1, $4), ENULL); }
    |    e '>' '=' e    { $$ = new('!', new('<', $1, $4), ENULL); }
    |    e '#' e        { $$ = new('#', $1, $3); }
    ;

expr_list:     e        { $$ = new(ELIST, ENULL, $1); }
    |    expr_list ',' e    { $$ = new(ELIST, $1, $3); }
    ;

range:   var ':' var    { $$.left = $1; $$.right = $3; }
    |    RANGE          { $$ = $1; }
    ;

var:     COL NUMBER     { $$.vp = lookat($2, $1);
                          $$.vf = 0;
                        }
    |    '$' COL NUMBER { $$.vp = lookat($3, $2);
                            $$.vf = FIX_COL;
                        }
    |    COL '$' NUMBER { $$.vp = lookat($3, $1);
                            $$.vf = FIX_ROW;
                        }
    |    '$' COL '$' NUMBER {
                          $$.vp = lookat($4, $2);
                          $$.vf = FIX_ROW | FIX_COL;
                        }
    |    VAR            {
                          $$ = $1.left;
                        }
    ;

var_or_range:   range     { $$ = $1; }
    |    var              { $$.left = $1; $$.right = $1; }
    ;

num:     NUMBER           { $$ = (double) $1; }
    |    FNUMBER          { $$ = $1; }
    |    '-' num          { $$ = -$2; }
    |    '+' num          { $$ = $2; }
    ;
strarg:  STRING           { $$ = $1; }
    |    var              {
                            char *s, *s1;
                            s1 = $1.vp->label;
                            if (!s1)
                            s1 = "NULL_STRING";
                            s = scxmalloc((unsigned)strlen(s1)+1);
                            (void) strcpy(s, s1);
                            $$ = s;
                          }
    ;


/* allows >=1 'setitem's to be listed in the same 'set' command
setlist :
    |    setlist    setitem
    ;

// things that you can 'set'
setitem    :
        //K_AUTO            { setauto(1); }
        //|    K_AUTOCALC        { setauto(1); }
    //|    '~' K_AUTO        { setauto(0); }
    //|    '~' K_AUTOCALC        { setauto(0); }
    //|    '!' K_AUTO        { setauto(0); }
    //|    '!' K_AUTOCALC        { setauto(0); }
    K_BYCOLS        { setorder(BYCOLS); }

    |    K_BYROWS        { setorder(BYROWS); }
    |    K_OPTIMIZE        { optimize = 1; }
    |    '~' K_OPTIMIZE        { optimize = 0; }
    |    '!' K_OPTIMIZE        { optimize = 0; }
    //|    K_NUMERIC        { numeric = 1; }
    //|    '~' K_NUMERIC        { numeric = 0; }
    //|    '!' K_NUMERIC        { numeric = 0; }
    |    K_PRESCALE        { prescale = 0.01; }
    |    '~' K_PRESCALE        { prescale = 1.0; }
    |    '!' K_PRESCALE        { prescale = 1.0; }
    //|    K_CELLCUR        { showcell = 1; }
    //|    '~' K_CELLCUR        { showcell = 0; }
    //|    '!' K_CELLCUR        { showcell = 0; }
    //|    K_TOPROW        { showtop = 1; }
    //|    '~' K_TOPROW        { showtop = 0; }
    //|    '!' K_TOPROW        { showtop = 0; }
    //|    K_AUTOINSERT        { autoinsert = 1; }
    //|    '~' K_AUTOINSERT    { autoinsert = 0; }
    //|    '!' K_AUTOINSERT    { autoinsert = 0; }
    //|    K_AUTOWRAP        { autowrap = 1; }
    //|    '~' K_AUTOWRAP        { autowrap = 0; }
    //|    '!' K_AUTOWRAP        { autowrap = 0; }
    |    K_CSLOP            { cslop = 0; }
    |    '~' K_CSLOP        { cslop = 1; }
    |    '!' K_CSLOP        { cslop = 1; }
    |    K_COLOR            { color = 1;
                      if (usecurses && has_colors()) {
                        color_set(1, NULL);
                        bkgd(COLOR_PAIR(1) | ' ');
                        FullUpdate++;
                      }
                    }
    |    '!' K_COLOR        { color = 0;
                      if (usecurses && has_colors()) {
                        color_set(0, NULL);
                        bkgd(COLOR_PAIR(0) | ' ');
                      }
                    }
    |    '~' K_COLOR        { color = 0;
                      if (usecurses && has_colors()) {
                        color_set(0, NULL);
                        bkgd(COLOR_PAIR(0) | ' ');
                      }
                    }
    //|    K_COLORNEG        { colorneg = 1; }
    //|    '!' K_COLORNEG        { colorneg = 0; }
    //|    '~' K_COLORNEG        { colorneg = 0; }
    //|    K_COLORERR        { colorerr = 1; }
    //|    '!' K_COLORERR        { colorerr = 0; }
    //|    '~' K_COLORERR        { colorerr = 0; }
    //|    K_BRAILLE        { braille = 1; }
    //|    '!' K_BRAILLE        { braille = 0; }
    //|    '~' K_BRAILLE        { braille = 0; }
    |    K_ITERATIONS '=' NUMBER    { setiterations($3); }
    |    K_TBLSTYLE '=' NUMBER    { tbl_style = $3; }
    |    K_TBLSTYLE '=' K_TBL    { tbl_style = TBL; }
    |    K_TBLSTYLE '=' K_LATEX    { tbl_style = LATEX; }
    |    K_TBLSTYLE '=' K_SLATEX    { tbl_style = SLATEX; }
    |    K_TBLSTYLE '=' K_TEX    { tbl_style = TEX; }
    |    K_TBLSTYLE '=' K_FRAME    { tbl_style = FRAME; }
    |    K_RNDTOEVEN        { rndtoeven = 1; FullUpdate++; }
    |    '!' K_RNDTOEVEN        { rndtoeven = 0; FullUpdate++; }
    |    '~' K_RNDTOEVEN        { rndtoeven = 0; FullUpdate++; }
    //|    K_CRACTION '=' NUMBER    { craction = $3; }
    //|    K_ROWLIMIT '=' NUMBER    { rowlimit = $3; }
    //|    K_COLLIMIT '=' NUMBER    { collimit = $3; }
    //|    K_PAGESIZE '=' NUMBER    { pagesize = $3; }
    |    K_LOCALE        {
#ifdef USELOCALE
                      struct  lconv *locstruct;
                      char    *loc;

                      loc = setlocale(LC_ALL, "");
                      if (loc != NULL) {
                        locstruct = localeconv();
                        dpoint = (locstruct->decimal_point)[0];
                        thsep = (locstruct->thousands_sep)[0];
                      }
                      else {
                        dpoint = '.';
                        thsep = ',';
                      }
                      FullUpdate++;
#else
                      error("Locale support not available");
#endif
                    }
    |    '!' K_LOCALE        {
                      dpoint = '.';
                      thsep = ',';
                      FullUpdate++;
                    }
    |    '~' K_LOCALE        {
                      dpoint = '.';
                      thsep = ',';
                      FullUpdate++;
                    }
      ;

/* types of errors, to 'goto'
errlist :

        K_ERROR range        { num_search((double)0,
                      $2.left.vp->row, $2.left.vp->col,
                      $2.right.vp->row, $2.right.vp->col,
                      CELLERROR, 1); }
    | K_ERROR            { num_search((double)0, 0, 0,
                      maxrow, maxcol, CELLERROR, 1); }

    |    K_INVALID range        { num_search((double)0,
                      $2.left.vp->row, $2.left.vp->col,
                      $2.right.vp->row, $2.right.vp->col,
                      CELLINVALID, 1); }

    |    K_INVALID        { num_search((double)0, 0, 0,
                      maxrow, maxcol, CELLINVALID, 1); }
    ;
*/
