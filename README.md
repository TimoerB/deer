# Deer
Lightweight deploy manager to create, run and manage executable tarballs for any software


## Install Deer

To install deer, open a terminal with root access and copypaste this code:

```
wget -q "https://deer.obss.be/install.tar.gz" -O deer.tar.gz
tar -xf deer.tar.gz
chmod +x run.sh
sudo bash run.sh
rm run.sh
```

You can still use deer without making an account, but only to read repo's and execute them on your servers. To be able to push your software and repo's to the deer cloud, please make an account: https://deer.obss.be

## Quick Start

One of the first things you'll want to do is to turn safemode off. This is because safemode only allows you to download your own repo's as a precaution. Most of the time, safemode will have to be turned off: `deer safemode off`

* Create repo from directory <dir>

Make sure to always navigate to the directory you want to push. Deer will package everything in that directory and push it to the cloud. To do this, you need to first set your deer id: `deer id <myDeerId>`

Where <myDeerId> is the value found by logging in to your personal dashboard on the deer cloud. Next, you can push your <dir> directory to the cloud:

```
cd <dir>
deer push <dir>
```

* Run repo

Only a repo name is needed to download and run it: `deer <repo>`

For example to run a barebones python webserver: `deer py-web`

* Download and run repo to <anotherDir>

Sometimes it is necessary to download the repo files to specific directory. This can be accomplished in like manner: `deer <repo> to <anotherDir>`

When this is the case, deer can't automatically manage this repo and will thus have to be run manually.

* Check the logs

Any output from the deer apps will be directed to its logs: `deer logs <repo>`

Or to follow incoming logs too: `deer logs -f <repo>`

* List deer files

To see downloaded repo's on your local machine, run: `deer ls`

To see which repo has stopped or is still running: `deer ps`

* Deploy multiple deer files in a herd from a file

Probably the main feature of deer is to combine a group of deer files into a herd. Navigate to your directory and make a *.herd file. Each line in the file represents the repo name that is pushed to the deer cloud.

```
deer herd -f <myHerd.herd>
```

You can also push this herd file to the cloud. To run the herd, simply execute: `deer herd <myHerd>`

* Clean up

Having a lot of running deer apps can turn out to be dirty. To delete all downloaded repo's, run: `deer clean`

Or remove one repo: `deer rm <repo>`

## Updates

Last but not least, don't forget to regularly update deer! `sudo deer update`

## Handy Repo Examples

- py-web: barebones python webserver running standard on localhost:9999
- helloworld: print one message to the log file
- loopy: app that prints the time every 5 seconds


