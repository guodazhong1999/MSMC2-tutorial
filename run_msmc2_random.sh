#!/bin/bash

set -euo pipefail


############################################################
# MSMC2 Random Resampling Pipeline
#
# 每次：
#   Pop1 随机抽取 2 个样本
#   Pop2 随机抽取 2 个样本
#
# Step 1: generate_multihetsep.py
# Step 2: MSMC2 Pop1
# Step 3: MSMC2 Pop2
# Step 4: MSMC2 Across populations
# Step 5: combineCrossCoal.py
#
############################################################


############################
# 默认参数
############################

REPEAT=""
POP1=""
POP2=""
THREAD=4

SAMPLE_MASK=""
GENOME_MASK_PREFIX=""
VCF=""

MSMC_TOOLS=""
CHR=""

POP1_SAMPLE_FILE="pop1sample.txt"
POP2_SAMPLE_FILE="pop2sample.txt"

OUTDIR=""

MSMC2="msmc2_Linux"


############################
# 帮助信息
############################

usage() {

cat << 'EOF'

==============================================================
MSMC2 Random Resampling Pipeline
==============================================================

Usage:

bash run_msmc2_random.sh \
    --repeat 100 \
    --pop1 CI \
    --pop2 CII \
    --thread 8 \
    --sample_mask /absolute/path/to/mask_bed \
    --genome_mask_prefix /absolute/path/to/genome \
    --vcf /absolute/path/to/02.phase_vcf \
    --msmc_tools /absolute/path/to/msmc-tools \
    --Chr /absolute/path/to/Chr.txt


Required parameters
--------------------------------------------------------------

--repeat

    重复次数

    例如：
    --repeat 100


--pop1

    Population 1 名称

    例如：
    --pop1 CI


--pop2

    Population 2 名称

    例如：
    --pop2 CII


--thread

    MSMC2 使用线程数

    例如：
    --thread 16


--sample_mask

    样本 mask 文件所在目录的绝对路径

    程序寻找：

    sample_mask/sample.Chr01.mask.bed.gz
    sample_mask/sample.Chr02.mask.bed.gz
    ...


--genome_mask_prefix

    基因组 mask 文件前缀

    例如：

    --genome_mask_prefix /data/SNPable/genome

    如果 Chr.txt 为：

    01
    02
    03

    程序寻找：

    /data/SNPable/genome.Chr01.mask.bed
    /data/SNPable/genome.Chr02.mask.bed
    /data/SNPable/genome.Chr03.mask.bed


--vcf

    phased VCF 文件所在目录的绝对路径

    例如：

    --vcf /data/project/02.phase_vcf

    程序寻找：

    /data/project/02.phase_vcf/sample.Chr01.phased.vcf.gz
    /data/project/02.phase_vcf/sample.Chr02.phased.vcf.gz
    ...


--msmc_tools

    msmc-tools 所在目录的绝对路径

    该目录必须包含：

    generate_multihetsep.py
    combineCrossCoal.py


--Chr

    染色体编号文件

    例如：

    Chr01
    Chr02
    Chr03
    ...
    Chr16


Optional parameters
--------------------------------------------------------------

--pop1sample

    Pop1 样本列表

    默认：
    pop1sample.txt


--pop2sample

    Pop2 样本列表

    默认：
    pop2sample.txt


--outdir

    输出目录

    默认：
    POP1vsPOP2


-h, --help

    显示帮助信息


Example
--------------------------------------------------------------

bash run_msmc2_random.sh \
    --repeat 100 \
    --pop1 CI \
    --pop2 CII \
    --thread 16 \
    --sample_mask /data/project/mask_bed \
    --genome_mask_prefix /data/project/SNPable/genome \
    --vcf /data/project/02.phase_vcf \
    --msmc_tools /home/user/software/msmc-tools \
    --Chr /data/project/Chr.txt

==============================================================

EOF

exit 0

}

############################
# 参数解析
############################

while [[ $# -gt 0 ]]; do

    case "$1" in

        --repeat)
            REPEAT="$2"
            shift 2
            ;;

        --pop1)
            POP1="$2"
            shift 2
            ;;

        --pop2)
            POP2="$2"
            shift 2
            ;;

        --thread)
            THREAD="$2"
            shift 2
            ;;

        --sample_mask)
            SAMPLE_MASK="$2"
            shift 2
            ;;

        --genome_mask_prefix)
            GENOME_MASK_PREFIX="$2"
            shift 2
            ;;

        --vcf)
            VCF="$2"
            shift 2
            ;;

        --msmc_tools)
            MSMC_TOOLS="$2"
            shift 2
            ;;

        --Chr)
            CHR="$2"
            shift 2
            ;;

        --pop1sample)
            POP1_SAMPLE_FILE="$2"
            shift 2
            ;;

        --pop2sample)
            POP2_SAMPLE_FILE="$2"
            shift 2
            ;;

        --outdir)
            OUTDIR="$2"
            shift 2
            ;;

        -h|--help)
            usage
            ;;

        *)
            echo
            echo "ERROR: Unknown parameter: $1"
            echo
            usage
            ;;

    esac

done


############################
# 必要参数检查
############################

if [[ -z "$REPEAT" ]]; then
    echo "ERROR: --repeat is required"
    exit 1
fi


if [[ -z "$POP1" ]]; then
    echo "ERROR: --pop1 is required"
    exit 1
fi


if [[ -z "$POP2" ]]; then
    echo "ERROR: --pop2 is required"
    exit 1
fi


if [[ -z "$THREAD" ]]; then
    echo "ERROR: --thread is required"
    exit 1
fi


if [[ -z "$SAMPLE_MASK" ]]; then
    echo "ERROR: --sample_mask is required"
    exit 1
fi


if [[ -z "$GENOME_MASK_PREFIX" ]]; then
    echo "ERROR: --genome_mask_prefix is required"
    exit 1
fi


if [[ -z "$VCF" ]]; then
    echo "ERROR: --vcf is required"
    exit 1
fi


if [[ -z "$MSMC_TOOLS" ]]; then
    echo "ERROR: --msmc_tools is required"
    exit 1
fi


if [[ -z "$CHR" ]]; then
    echo "ERROR: --Chr is required"
    exit 1
fi


############################
# 默认输出目录
############################

if [[ -z "$OUTDIR" ]]; then
    OUTDIR="${POP1}vs${POP2}"
fi


############################
# 输入文件检查
############################

if [[ ! -f "$POP1_SAMPLE_FILE" ]]; then

    echo "ERROR: Cannot find Pop1 sample file:"
    echo "$POP1_SAMPLE_FILE"

    exit 1

fi


if [[ ! -f "$POP2_SAMPLE_FILE" ]]; then

    echo "ERROR: Cannot find Pop2 sample file:"
    echo "$POP2_SAMPLE_FILE"

    exit 1

fi


if [[ ! -f "$CHR" ]]; then

    echo "ERROR: Cannot find Chr file:"
    echo "$CHR"

    exit 1

fi


############################
# 输入目录检查
############################

if [[ ! -d "$SAMPLE_MASK" ]]; then

    echo "ERROR: Sample mask directory does not exist:"
    echo "$SAMPLE_MASK"

    exit 1

fi


if [[ ! -d "$VCF" ]]; then

    echo "ERROR: VCF directory does not exist:"
    echo "$VCF"

    exit 1

fi


if [[ ! -d "$MSMC_TOOLS" ]]; then

    echo "ERROR: msmc-tools directory does not exist:"
    echo "$MSMC_TOOLS"

    exit 1

fi


############################
# msmc-tools 程序
############################

GENERATE_MULTIHetSEP="${MSMC_TOOLS}/generate_multihetsep.py"

COMBINE_CROSSCOAL="${MSMC_TOOLS}/combineCrossCoal.py"


############################
# 检查 msmc-tools 程序
############################

if [[ ! -f "$GENERATE_MULTIHetSEP" ]]; then

    echo "ERROR: Cannot find:"
    echo "$GENERATE_MULTIHetSEP"

    exit 1

fi


if [[ ! -f "$COMBINE_CROSSCOAL" ]]; then

    echo "ERROR: Cannot find:"
    echo "$COMBINE_CROSSCOAL"

    exit 1

fi


############################
# 检查 MSMC2
############################

if ! command -v "$MSMC2" >/dev/null 2>&1 && [[ ! -x "$MSMC2" ]]; then

    echo "ERROR: Cannot find MSMC2 executable:"
    echo "$MSMC2"

    echo
    echo "Please make sure msmc2_Linux is in PATH"
    echo "or modify MSMC2 variable in this script."

    exit 1

fi


############################
# 检查样本数量
############################

N_POP1=$(grep -v '^$' "$POP1_SAMPLE_FILE" | wc -l)

N_POP2=$(grep -v '^$' "$POP2_SAMPLE_FILE" | wc -l)


if [[ "$N_POP1" -lt 2 ]]; then

    echo "ERROR:"
    echo "$POP1_SAMPLE_FILE contains fewer than 2 samples."

    exit 1

fi


if [[ "$N_POP2" -lt 2 ]]; then

    echo "ERROR:"
    echo "$POP2_SAMPLE_FILE contains fewer than 2 samples."

    exit 1

fi


############################
# 创建输出目录
############################

mkdir -p "$OUTDIR"


############################
# 输出运行参数
############################

echo
echo "======================================================"
echo " MSMC2 Random Resampling"
echo "======================================================"
echo " Population 1       : $POP1"
echo " Population 2       : $POP2"
echo " Pop1 sample file   : $POP1_SAMPLE_FILE"
echo " Pop2 sample file   : $POP2_SAMPLE_FILE"
echo " Repeat             : $REPEAT"
echo " Threads            : $THREAD"
echo " Sample mask        : $SAMPLE_MASK"
echo " Genome mask prefix : $GENOME_MASK_PREFIX"
echo " VCF directory      : $VCF"
echo " MSMC tools         : $MSMC_TOOLS"
echo " Chr file           : $CHR"
echo " Output             : $OUTDIR"
echo "======================================================"
echo


############################################################
# 主循环
############################################################

for ((rep=1; rep<=REPEAT; rep++)); do


    ############################
    # repeat 目录
    ############################

    REP_NAME=$(printf "repeat_%03d" "$rep")

    REP_DIR="${OUTDIR}/${REP_NAME}"

    mkdir -p "$REP_DIR"


    echo
    echo "======================================================"
    echo " Repeat ${rep}/${REPEAT}"
    echo "======================================================"


    ############################
    # Pop1 随机抽取两个不同样本
    ############################

    POP1_SAMPLE1=$(shuf -n 1 "$POP1_SAMPLE_FILE")

    POP1_SAMPLE2=$(shuf -n 1 "$POP1_SAMPLE_FILE")


    while [[ "$POP1_SAMPLE1" == "$POP1_SAMPLE2" ]]; do

        POP1_SAMPLE2=$(shuf -n 1 "$POP1_SAMPLE_FILE")

    done


    ############################
    # Pop2 随机抽取两个不同样本
    ############################

    POP2_SAMPLE1=$(shuf -n 1 "$POP2_SAMPLE_FILE")

    POP2_SAMPLE2=$(shuf -n 1 "$POP2_SAMPLE_FILE")


    while [[ "$POP2_SAMPLE1" == "$POP2_SAMPLE2" ]]; do

        POP2_SAMPLE2=$(shuf -n 1 "$POP2_SAMPLE_FILE")

    done


    ############################
    # 保存随机抽样信息
    ############################

    SAMPLE_INFO="${REP_DIR}/sample_info.txt"


    {
        echo "Repeat: ${rep}"
        echo
        echo "Population_1: ${POP1}"
        echo "Sample1: ${POP1_SAMPLE1}"
        echo "Sample2: ${POP1_SAMPLE2}"
        echo
        echo "Population_2: ${POP2}"
        echo "Sample1: ${POP2_SAMPLE1}"
        echo "Sample2: ${POP2_SAMPLE2}"

    } > "$SAMPLE_INFO"


    ############################
    # 输出随机样本
    ############################

    echo
    echo "Selected samples:"
    echo
    echo "  ${POP1}:"
    echo "      ${POP1_SAMPLE1}"
    echo "      ${POP1_SAMPLE2}"
    echo
    echo "  ${POP2}:"
    echo "      ${POP2_SAMPLE1}"
    echo "      ${POP2_SAMPLE2}"


    ############################
    # 四个样本组成的文件前缀
    ############################

    PREFIX="${POP1_SAMPLE1}.${POP1_SAMPLE2}.${POP2_SAMPLE1}.${POP2_SAMPLE2}"


    ########################################################
    # Step 1
    # generate_multihetsep.py
    ########################################################

    echo
    echo "[1/5] generate_multihetsep.py"


    while read -r i; do

        [[ -z "$i" ]] && continue


        echo "Processing chromosome: ${i}"


        ############################
        # 样本 mask
        ############################

        MASK1="${SAMPLE_MASK}/${POP1_SAMPLE1}.${i}.mask.bed.gz"

        MASK2="${SAMPLE_MASK}/${POP1_SAMPLE2}.${i}.mask.bed.gz"

        MASK3="${SAMPLE_MASK}/${POP2_SAMPLE1}.${i}.mask.bed.gz"

        MASK4="${SAMPLE_MASK}/${POP2_SAMPLE2}.${i}.mask.bed.gz"


        ############################
        # 基因组 mask
        ############################

        GENOME_MASK="${GENOME_MASK_PREFIX}${i}.mask.bed"


        ############################
        # phased VCF
        ############################

        VCF1="${VCF}/${POP1_SAMPLE1}.${i}.phased.vcf.gz"

        VCF2="${VCF}/${POP1_SAMPLE2}.${i}.phased.vcf.gz"

        VCF3="${VCF}/${POP2_SAMPLE1}.${i}.phased.vcf.gz"

        VCF4="${VCF}/${POP2_SAMPLE2}.${i}.phased.vcf.gz"


        ############################
        # 检查文件
        ############################

        for file in \
            "$MASK1" \
            "$MASK2" \
            "$MASK3" \
            "$MASK4" \
            "$GENOME_MASK" \
            "$VCF1" \
            "$VCF2" \
            "$VCF3" \
            "$VCF4"
        do

            if [[ ! -f "$file" ]]; then

                echo
                echo "ERROR: Missing file:"
                echo "$file"
                echo

                exit 1

            fi

        done


        ############################
        # generate_multihetsep
        ############################

        python "$GENERATE_MULTIHetSEP" \
            --mask="$MASK1" \
            --mask="$MASK2" \
            --mask="$MASK3" \
            --mask="$MASK4" \
            --mask="$GENOME_MASK" \
            "$VCF1" \
            "$VCF2" \
            "$VCF3" \
            "$VCF4" \
            > "${REP_DIR}/multihetsep.${PREFIX}.Chr${i}.txt"


    done < "$CHR"


    ########################################################
    # 创建 MSMC2 输入文件列表
    ########################################################

    MSMC_INPUTS=()


    while read -r i; do

        [[ -z "$i" ]] && continue

        MSMC_INPUTS+=(
            "${REP_DIR}/multihetsep.${PREFIX}.Chr${i}.txt"
        )

    done < "$CHR"


    ########################################################
    # Step 2
    # MSMC2 Pop1
    ########################################################

    echo
    echo "[2/5] MSMC2 ${POP1}"


    POP1_OUT="${REP_DIR}/${POP1_SAMPLE1}.${POP1_SAMPLE2}_${POP1}_${POP1}vs${POP2}.msmc2.out"


    "$MSMC2" \
        -t "$THREAD" \
        -s \
        -I 0,1,2,3 \
        -o "$POP1_OUT" \
        "${MSMC_INPUTS[@]}"


    ########################################################
    # Step 3
    # MSMC2 Pop2
    ########################################################

    echo
    echo "[3/5] MSMC2 ${POP2}"


    POP2_OUT="${REP_DIR}/${POP2_SAMPLE1}.${POP2_SAMPLE2}_${POP2}_${POP1}vs${POP2}.msmc2.out"


    "$MSMC2" \
        -t "$THREAD" \
        -s \
        -I 4,5,6,7 \
        -o "$POP2_OUT" \
        "${MSMC_INPUTS[@]}"


    ########################################################
    # Step 4
    # MSMC2 Across populations
    ########################################################

    echo
    echo "[4/5] MSMC2 across populations"


    ACROSS_OUT="${REP_DIR}/${PREFIX}_${POP1}vs${POP2}.across.msmc2.out"


    "$MSMC2" \
        -t "$THREAD" \
        -s \
        -I 0-4,0-5,0-6,0-7,1-4,1-5,1-6,1-7,2-4,2-5,2-6,2-7,3-4,3-5,3-6,3-7 \
        -o "$ACROSS_OUT" \
        "${MSMC_INPUTS[@]}"


    ########################################################
    # Step 5
    # combineCrossCoal.py
    ########################################################

    echo
    echo "[5/5] combineCrossCoal.py"


    COMBINED_OUT="${REP_DIR}/${PREFIX}.combined.msmc2.final.txt"


    python "$COMBINE_CROSSCOAL" \
        "$ACROSS_OUT" \
        "$POP1_OUT" \
        "$POP2_OUT" \
        > "$COMBINED_OUT"


    ########################################################
    # 完成标记
    ########################################################

    touch "${REP_DIR}/DONE"


    echo
    echo "Repeat ${rep} completed."
    echo
    echo "Output directory:"
    echo "$REP_DIR"
    echo

done


############################################################
# 全部完成
############################################################

echo
echo "======================================================"
echo " ALL REPEATS COMPLETED"
echo "======================================================"
echo
echo "Output directory:"
echo "$OUTDIR"
echo
