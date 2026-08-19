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

	~/software/runsmcpp/seqbility-20091110/splitfa genome.fasta 35 > genome.splitfa.35.fa
	
	bwa aln -t 8 -R 1000000 -O 3 -E 3 genome.fasta genome.splitfa.35.fa > genome.splitfa.35.sai
	
	bwa samse -f genome.splitfa.35.sam genome.fasta genome.splitfa.35.sai genome.splitfa.35.fa
	
	perl ~/software/runsmcpp/seqbility-20091110/gen_raw_mask.pl genome.splitfa.35.sam > genome.rawMask_35.fa
	
	~/software/runsmcpp/seqbility-20091110/gen_mask -l 35 -r 0.5 genome.rawMask_35.fa > genome.mask_35_50.fa
	
	python makeMappabilityMask.py
## 2 统计样本测序深度（这个可以只统计你需要分析的样本测序深度）

	for i in `cat sample.txt`;
        do for j in `cat Chr.txt`;
        do
                samtools depth -r ${j} ./00.data/${i}.bam |awk '{sum += $3} END {print sum / NR}' >> ${i}.depth.txt;
                done
        done

## 3 calling VCF (特别需要注意bcftools和samtools的版本，在旧版本中有些选项功能移除了)


	for i in `cat sample.txt`;
	        do for j in `cat Chr.txt`;
	                do  bcftools mpileup -q 20 -Q 20 -C 50 -Ou -r ${j} -f ./genome.fasta ./00.data/${i}.bam | bcftools call -c -V indels --threads 8 | ~/software/msmc-tools/bamCaller.py ${depth} ${i}.${j}.mask.bed.gz |bgzip -c > ./01.calling_vcf/${i}.${j}.vcf.gz #${depth}填每个样本统计出来的测序深度，每个样本会不一样，你要嫌麻烦你就填平均值运行所有样本的计算
	                done
	        done

## 4 对每个样本的VCF文件进行分型

以下是批量生成分型分析的脚本

	#!/bin/bash
	# 生成每个样本的独立作业脚本
	
	# 读取样本列表
	while read sample; do
	    cat > run_${sample}.sh << 'EOF'
	#!/bin/bash
	#CSUB -J ${sample}
	#CSUB -q ${list}
	#CSUB -o %J.out 
	#CSUB -e %J.error
	#CSUB -R span[hosts=1]
	
	# 处理当前样本的所有染色体
	for chr in `cat Chr.txt`; do
	    whatshap phase \
	        -o ${sample}.${chr}.phased.vcf \
	        --reference=genome.fasta \
	        ./01.calling_vcf/${sample}.${chr}.vcf.gz \
	        ./00.data/${sample}.bam
	done
	EOF
	    
	    # 替换脚本中的sample变量
	    sed -i "s/\${sample}/$sample/g" run_${sample}.sh
	    
	    # 添加执行权限
	    chmod +x run_${sample}.sh
	    
	    echo "Generated script for sample: $sample"
	    
	done < sample.txt

**需要特别注意如果需要进行relative cross-coalescence rate分析就一定要进行分型这一步操作，msmc2文献中特别强调了这个问题**
