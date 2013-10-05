#!/usr/sbin/dtrace -s


 #pragma D option quiet
 #pragma D option switchrate=10hz

 /*
  * Init Variables
  */
 dtrace:::BEGIN 
 {
	last_event[""] = 0;
 }


 /*
  * Reset last_event for disk idle -> start
  * this prevents idle time being counted as disk time.
  */
 io:::start
 /! pending[args[1]->dev_statname]/
 {
	/* save last disk event */
	last_event[args[1]->dev_statname] = timestamp;
 }

 /*
  * Store entry details
  */
 io:::start
 {
	/* these are used as a unique disk event key, */
 	this->dev = args[0]->b_edev;
 	this->blk = args[0]->b_blkno;

	/* save disk event details, */
 	start_uid[this->dev, this->blk] = (int)uid;
 	start_pid[this->dev, this->blk] = pid;
 	start_ppid[this->dev, this->blk] = ppid;
 	start_args[this->dev, this->blk] = (char *)curpsinfo->pr_psargs;
 	start_comm[this->dev, this->blk] = execname;
 	start_time[this->dev, this->blk] = timestamp;

	/* increase disk event pending count */
	pending[args[1]->dev_statname]++;
 }

 /*
  * Process and Print completion
  */
 io:::done
 /start_time[args[0]->b_edev, args[0]->b_blkno]/
 {
	/* decrease disk event pending count */
	pending[args[1]->dev_statname]--;

	/*
	 * Process details
	 */

 	/* fetch entry values */
 	this->dev = args[0]->b_edev;
 	this->blk = args[0]->b_blkno;
 	this->suid = start_uid[this->dev, this->blk];
 	this->spid = start_pid[this->dev, this->blk];
 	this->sppid = start_ppid[this->dev, this->blk];
 	self->sargs = (int)start_args[this->dev, this->blk] == 0 ? 
 	    "" : start_args[this->dev, this->blk];
 	self->scomm = start_comm[this->dev, this->blk];
 	this->stime = start_time[this->dev, this->blk];
	this->etime = timestamp; /* endtime */
	this->delta = this->etime - this->stime;
	this->dtime = last_event[args[1]->dev_statname] == 0 ? 0 :
	    timestamp - last_event[args[1]->dev_statname];

 	/* memory cleanup */
 	start_uid[this->dev, this->blk]  = 0;
 	start_pid[this->dev, this->blk]  = 0;
 	start_ppid[this->dev, this->blk] = 0;
 	start_args[this->dev, this->blk] = 0;
 	start_time[this->dev, this->blk] = 0;
 	start_comm[this->dev, this->blk] = 0;
 	start_rw[this->dev, this->blk]   = 0;

	/*
	 * Print details
	 */

	printf("%d ⟩ %s ⟩ %d ⟩ %s ⟩ %s ⟩ %s ⟩ %s ⟩ %s\n",
		this->spid,
		args[0]->b_flags & B_READ ? "R" : "W",
		args[0]->b_bcount,
		self->scomm,
		self->sargs,
		args[1]->dev_pathname,
		args[2]->fi_mount,
		args[2]->fi_pathname
	      );

	/* save last disk event */
	last_event[args[1]->dev_statname] = timestamp;

	/* cleanup */
	self->scomm = 0;
	self->sargs = 0;
 }

 /*
  * Prevent pending from underflowing
  * this can happen if this program is started during disk events.
  */
 io:::done
 /pending[args[1]->dev_statname] < 0/
 {
	pending[args[1]->dev_statname] = 0;
 }



/*
 * vim:ft=dtrace:ts=8:sw=4:tw=4:fmr=⟨⟨⟨,⟩⟩⟩:fdm=syntax:
 */
