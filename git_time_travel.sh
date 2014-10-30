#!/bin/sh
# Run a command over a sequence of commits and get analytics on repo activity
# Example:
# ./gradethis origin/master 'make clean && make' > graded/build_history.txt

clear

help(){
  echo "\n\nGradeThis!\n\n A tool for grading classes based on repository activity."
  echo "\n\n Usage:\n"
  echo "   help    - Shows this helpful message."
  echo "   analyze - Produces analytics on authors of the repo."
  echo "   graph   - Shows a pretty git log. "
  echo "   walk    - Walks the repository backwards and logs commits that broke the build. (Slow)"
  echo "   again   - Repeats. Does not force a redo on things."
  echo "   all     - Does everything. (Really Slow, take a coffee break)"
  echo "\n"
}

if [ ! $1 ]; then
  help
  exit 1
fi

hr(){
  echo "\n################################################################################\n"
}

br(){
  echo ""
}
cleanup() {
  git checkout $start_branch > /dev/null 2>/dev/null
}

already_passed() {
  obdata=${ref_name}-$t-$1
  obhash=`echo $obdata | git hash-object --stdin`
  git cat-file blob $obhash > /dev/null 2>/dev/null \
      && echo "Already ${ref_name} $1"
}

passed_on() {
  obdata=${ref_name}-$t-$1
  echo $obdata | git hash-object -w --stdin > /dev/null
  echo "Passed: $1."
}

broke_on() {
  git log --pretty="format:%an broke the build on %h (%s)%n. Complain to: %ae " -n 1 $1
  cleanup

}

new_test() {
  echo "Testing $2"
  git reset --hard $v && eval "$2" && passed_on $1 || broke_on $v
  status=$?
  if test -n "$run_once"; then
      cleanup
      exit $status
  fi
}




analyze(){
  hr
  echo "\nCounting commits for each user and writing to grading/authors.txt ... "
  git log --all | grep 'Author' | awk '{print $2 }' | sort | uniq -c | sort -nr > grading/authors.txt
  echo "\n  Top contributers by commit count:\n"
  head -5 grading/authors.txt

  br
  hr

  echo "\nFinding instances of -force and writing to grading/reflog.txt ..."
  git reflog origin/master | grep forced > grading/reflog.txt
  echo "\n   Results:\n"
  head -3 grading/reflog.txt
  br

}

walk(){
  hr
  echo "\n\nFinding users who broke the build and pushed...\n"
  eigenMake --force origin/master 'make clean && make' | cat > grading/build_history.txt
  cat grading/build_history.txt | grep broke | cat > grading/build_breakers.txt
  echo "\n\n"
  tail -5 grading/build_breakers.txt
  br
}

check_before_walk(){
  [ -f "grading/build_history.txt" ] && hr && echo "\nPeople who broke the build: \n" && tail -5 grading/build_breakers.txt || walk;
}
    
graph(){
  hr
  echo "\nMaking a pretty graph...\n"
  git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit | cat > grading/graph.txt
  tail -16 grading/graph.txt
  br
}

again(){
  analyze && graph && check_before_walk
}

all(){
  analyze && graph && walk
}




eigenMake(){

  t=
  force=
  run_once=
  ref_name=pass

  # The tree must be really really clean.
  if ! git update-index --ignore-submodules --refresh > /dev/null; then
      echo >&2 "cannot rebase: you have unstaged changes"
      git diff-files --name-status -r --ignore-submodules -- >&2
      exit 1
  fi
  diff=$(git diff-index --cached --name-status -r --ignore-submodules HEAD --)
  case "$diff" in
      ?*) echo >&2 "cannot rebase: your index contains uncommitted changes"
          echo >&2 "$diff"
          exit 1
          ;;
  esac

  start_branch=`git rev-parse --symbolic-full-name HEAD | sed s,refs/heads/,,`
  git checkout `git rev-parse HEAD` > /dev/null 2>/dev/null

  while test $# != 0
  do
      case "$1" in
          --force)
              force=yes
              ;;
          --once)
              run_once=yes
              ;;
          --ref-name)
              ref_name=$2
              shift
              ;;
          *)
              break;
              ;;
      esac
      shift
  done

  t=`echo "$2" | git hash-object --stdin`

  for v in `git rev-list --reverse $1`
  do
      tree_ver=`git rev-parse "$v^{tree}"`
      test -z "$force" && already_passed $tree_ver || new_test $tree_ver "$2"
  done
  cleanup
  if test -n "$run_once"; then
      echo "All commits already passed for --once argument. Quiting."
      exit 127
  fi
}

$@
