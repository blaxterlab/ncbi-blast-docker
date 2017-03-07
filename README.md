## ncbi-blast docker container

NCBI-blast+ docker container that installs the latest ncbi-blast+ linux x64 binaries from
ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST

Rather than simply calling the blastn/blastx binaries, this container traps the command in a script which extracts
several command-line options, and uses them to set up a GNU parallel job to speed up the blasts. For a single query sequence this is not useful, but for many query sequences (a typical use case in our lab), splitting the input file into many chunks and running each one as a single thread process is faster than one multi-threaded blast job using -num_threads (see https://www.biostars.org/p/119614/). The script also writes the output as a gzipped file.

To run, you have to know the absolute paths of the query file, the input file, and the blastdb. The containing directories have to be mounted as special volumes (internal to the docker container) so that the docker container knows where to access these files, and where to write the output to.

```
docker run \
    --user   $UID:$GROUPS \
    --name   blast-test \
    --volume /dir/containing/input:/query \
    --volume /dir/containing/blastdb:/db \
    --volume /dir/containing/output:/out \
    blaxterlab/ncbi-blast:latest \
    blastn -query /query/input.fasta -db /db/nt -out /out/results.txt \
        -evalue 1e-10 -num_threads 48 -outfmt '6 std qlen slen'
```

The `--user $UID:$GROUPS` option is needed to ensure that the docker container writes files to the output directory as the same user who ran the command.

A shorter version of the command using option shorthands, and assuming that the input, blastdb and output are all in the current directory:

```
docker run -u $UID:$GROUPS --name blast-test \
    -v `pwd`:/query -v `pwd`:/db -v `pwd`:/out \
    blaxterlab/ncbi-blast:latest
    blastn -query /query/input.fasta -db /db/nt -out /out/results.txt \
      -evalue 1e-10 -num_threads 48 -outfmt '6 std qlen slen' 
```

The possible drawbacks of this approach are:
- Any blast options that use quotes (e.g., `-outfmt '6 std'` will need to be trapped explicitly (I have already done this for `outfmt` but there may be others that use quotes. All other options will be passed through as is to the blast executables
- Output formats that write headers or tails for each blast job will cause many such headers to be written to the output as each chunk is a separate blast job. XML formats especially will result in multiple XML files being concatenated, and will need some postprocessing to make the final file look like a single XML elemnt from a blast job (I think Blast2GO expects such output)
- I always prefer gzipped output, so the script writes to a gzipped file by default, which some may not expect
- It *is* possible to stream the query as stdin and the output as stdout, but I don't know enough about Docker to do that!
- There is little or no error checking in the wrapper script
