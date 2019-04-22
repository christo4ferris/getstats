if [ "$UPDATE_GIT" = "y" ]; then
    echo "Updating projects from git"
    if [ ! -d ${GITBASE} ] ; then
        DEBUG "Creating missing ${GITBASE}"
        mkdir -p ${GITBASE}
    fi
    grep -v '^#' $PROJECTS |
        while read project x; do
            if [ ! -d ${GITBASE}/${project} ] ; then
                DEBUG "Cloning missing ${project} from ${REPOBASE}/${project}"
                git clone ${REPOBASE}/${project} ${GITBASE}/${project}
            fi
            cd ${GITBASE}/${project}
            DEBUG "Fetching updates to ${project}"
            git pull 2>/dev/null
        done
fi

if [ "$GIT_STATS" = "y" ] ; then
    echo "Generating git commit logs"
    grep -v '^#' $PROJECTS |
        while read project revisions excludes x; do
            DEBUG "Generating git commit log for ${project}"
            cd ${GITBASE}/${project} && git checkout master
            # match possible dates of the format YYYY-MM-DD to use in
            # supplying git with a '--since DATE' paramter instead of a
            # range of changeset ids
            if IS_DATE $revisions; then
                DEBUG "Matched a git --since date of '${revisions}'"
                SINCE="--since ${revisions}"
            fi
            git log ${GITLOGARGS} --since="${SINCE}" > "${TEMPDIR}/${project}-commits.log"
            if [ -n "$excludes" ]; then
                awk "/^commit /{ok=1} /^commit ${excludes}/{ok=0} {if(ok) {print}}" \
                    < "${TEMPDIR}/${project}-commits.log" > "${TEMPDIR}/${project}-commits.log.new"
                mv "${TEMPDIR}/${project}-commits.log.new" "${TEMPDIR}/${project}-commits.log"
            fi
        done

    echo "Generating aggregate git stats for all projects"
    grep -v '^#' $PROJECTS |
        while read project x; do
            cat "${TEMPDIR}/${project}-commits.log" >> "${TEMPDIR}/git-commits.log"
        done
    echo "${OUTPUT_HEADER}" > "${TEMPDIR}/git-stats.txt"
    python gitdm  -n -y -z -x "${TEMPDIR}/git-stats.csv" < "${TEMPDIR}/git-commits.log" >> "${TEMPDIR}/git-stats.txt"
    echo "===============================================================" >> "${TEMPDIR}/git-stats.txt"
    echo "${OUTPUT_HEADER}" >> "${TEMPDIR}/git-stats.txt"
    echo "===============================================================" >> "${TEMPDIR}/git-stats.txt"
fi

DEBUG "Cleaning up"
cd ${BASEDIR}
rm -rf ${RELEASE} && mkdir ./stats/${RELEASE}
mv ${TEMPDIR}/*stats.txt ./stats/${RELEASE}
mv ${TEMPDIR}/*stats-all.txt ./stats/${RELEASE}
mv ${TEMPDIR}/*.csv ./stats/${RELEASE}

[ "$REMOVE_TEMPDIR" = "y" ] && rm -rf ${TEMPDIR} || echo "Not removing ${TEMPDIR}"

cat ./stats/${RELEASE}/git-stats.txt
