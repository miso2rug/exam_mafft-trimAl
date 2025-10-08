params.out = "${projectDir}/output"
params.cache = "${projectDir}/cache"
params.accession = "M21012" // accession number for reference sequence from genbank
params.input = "${projectDir}/input" // storage folder for sequences in fastaformat to be aligned against reference


process downloadRef {
    storeDir params.cache
    output:
        path "${params.accession}.fasta"
    script:
        """
        wget "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${params.accession}&rettype=fasta&retmode=text" -O ${params.accession}.fasta
        """
}

process mergeSeqs {
    storeDir params.cache
    input:
        path fastafiles
    output:
        path "${params.accession}_collect.fasta"
    script:
        """
        cat *.fasta >> ${params.accession}_collect.fasta
        """
}

process mafft {
    storeDir params.cache
    container "https://depot.galaxyproject.org/singularity/mafft%3A7.525--h031d066_1"
    input:
        path merged
    output:
        path "${merged.getSimpleName()}_aligned.fasta"
    script:
        """
        mafft ${merged} > ${merged.getSimpleName()}_aligned.fasta
        """
}

process trimAl {
    publishDir params.out, mode: 'copy', overwrite: true
    container "https://depot.galaxyproject.org/singularity/trimal%3A1.5.0--h9948957_2"
    input:
        path alignment
    output:
        path "${alignment.getSimpleName()}_trimmed.html"
        path "${alignment.getSimpleName()}_trimmed.fasta"
    script:
        """
        trimal -in ${alignment} -out ${alignment.getSimpleName()}_trimmed.fasta -automated1 -htmlout ${alignment.getSimpleName()}_trimmed.html
        """

}

workflow {
    ch_download = downloadRef()
    ch_input = channel.fromPath("${params.input}/*.fasta")
    ch_allseqs = ch_download.concat(ch_input).collect()

    ch_merged = mergeSeqs(ch_allseqs)
    ch_aligned = mafft(ch_merged)
    trimAl(ch_aligned)
}
