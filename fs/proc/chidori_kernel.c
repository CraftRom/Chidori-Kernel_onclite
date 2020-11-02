#include <linux/fs.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <generated/compile.h>

static int chidori_kernel_proc_show(struct seq_file *m, void *v)
{
	seq_printf(m, "{\"kernel-name\": \"Chidori-Kernel\","
			"\"version\": \"10.0\","
			"\"type\": \"stable\","
			"\"buildtime\": \"%s\"}\n", CHIDORI_KERNEL_TIMESTAMP);
	return 0;
}

static int chidori_kernel_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, chidori_kernel_proc_show, NULL);
}

static const struct file_operations chidori_kernel_proc_fops = {
	.open		= chidori_kernel_proc_open,
	.read		= seq_read,
	.llseek	= seq_lseek,
	.release	= single_release,
};

static int __init proc_chidori_kernel_init(void)
{
	proc_create("chidori_kernel", 0, NULL, &chidori_kernel_proc_fops);
	return 0;
}
module_init(proc_chidori_kernel_init);
