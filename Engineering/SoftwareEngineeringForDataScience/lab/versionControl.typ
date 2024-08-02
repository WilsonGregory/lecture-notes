#set page(
  paper: "us-letter",
  header: align(center, text(17pt)[
    *Version Control with git*
  ]),
  numbering: "1",
)

#import "../style.typ": style_template
#show: doc => style_template(doc,)

= Foreword

If you have not heard of the idea of version control, or use git regularly, you are about to learn one of the most important tools in software development, second to only a text editor. It is so important that I put it right after the introduction session, even before the programming language session. We are going to learn about git, mostly from a contributor perspective. Down the road in this course you will also learn about git from a maintainer perspective.

There are many great guides on the internet about how to use git (#link("https://rogerdudler.github.io/git-guide/")[This] being my favorite guide), and it is not very useful for me to go through every existing git commands. In this session, we are going to learn some of the basic commands which you will use most frequently. In case you want to dig deeper into the git rabbit hole, ```bash git help [topic]``` actually provide a great selection of tutorials for you to follow. 

By the end of this session, you will know how to use all of the following commands

#set align(center)
#table(
  columns: (auto, auto),
  inset: 5pt,
  align: horizon,
  table.header(
    [*Command*], [*Function*],
  ),
  [init], [Initialize a new git repository],
  [add], [Add files to the staging area],
  [rm], [Remove files from the staging area],
  [commit], [Commit changes to the repository],
  [push], [Push changes to a remote repository],
  [pull], [Pull changes from a remote repository],
  [fetch], [Fetch changes from a remote repository],
  [log], [Show the commit history],
  [checkout], [Checkout another branch],
  [status], [Show the status of the repository],
  [branch], [List, create, or delete branches],
  [remote], [Manage remote repositories],
  [diff], [Show changes between commits],
  [rebase], [Reapply commits on top of another base tip],
  [merge], [Join two or more development histories together],
  [prune], [Remove remote branches that no longer exist],
  [reset], [Reset current HEAD to the specified state],
  [revert], [Revert some existing commits],
  [tag], [Create, list, delete or verify a tag object signed with GPG],
  [submodule], [Initialize, update or inspect submodules],
)

#pagebreak()

= Starting a repository

= Working on code

= Branching off

= Examining history

= Online collaboration

= Dealing with conflicts
