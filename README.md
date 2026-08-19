# MSMC2-tutorial
#这是本人在使用msmc2时一些心得做成的教程
## 0 所需要的软件以及安装
1 conda可直接安装以下几个软件

  bwa samtools bcftools whatshap
  
2 工具包

mask这一步所需要的seqbility工具包下载链接如下

  wget https://github.com/chaimol/runsmcpp/tree/master/seqbility-20091110

msmc2输入文件前处理所需要的工具包下载地址如下

  wget https://github.com/stschiff/msmc-tools

## 1 制作参考基因组的mask文件（不建议用msmc2给的脚本运行不知道什么bug运行速度非常慢）

	../../software/runsmcpp/seqbility-20091110/splitfa Final_T2T_Coconut_genome.fasta 35 > Coconut.splitfa.35.fa
	
	bwa aln -t 8 -R 1000000 -O 3 -E 3 Final_T2T_Coconut_genome.fasta Coconut.splitfa.35.fa > Coconut.splitfa.35.sai
	
	bwa samse -f Coconut.splitfa.35.sam Final_T2T_Coconut_genome.fasta Coconut.splitfa.35.sai Coconut.splitfa.35.fa
	
	perl ../../software/runsmcpp/seqbility-20091110/gen_raw_mask.pl Coconut.splitfa.35.sam > Coconut.rawMask_35.fa
	
	../../software/runsmcpp/seqbility-20091110/gen_mask -l 35 -r 0.5 Coconut.rawMask_35.fa > Coconut.mask_35_50.fa
	
	python makeMappabilityMask.py
