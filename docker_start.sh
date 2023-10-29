#!/bin/bash

git clone "$GIT_REPO" &&
    cd "$GIT_REPO_NAME"

if [ "$BRANCH" != "main" ]; then
    git checkout "$BRANCH"
else
    echo -e "\n---- Using main branch ----\n"
fi

if [ -z "$GIT_PAT" ]; then
    echo -e "\n---- No GIT_PAT provided, skipping PR creation ----\n"
else
    echo -e "\n---- GIT_PAT provided, creating PR ----\n"
fi
#
echo "Run Benchmark (5k posts)" &&
    ./run.sh "$TEST_NAME" raw_results.md &&
    #
    echo "Generate $RUN2 posts" &&
    python gen_fake_posts.py "$RUN2" &&
    #
    echo "Run Benchmark ($RUN2 posts)" &&
    ./run.sh "$TEST_NAME" raw_results.md append &&
    #
    echo "Generate $RUN3 posts" &&
    python gen_fake_posts.py "$RUN3" &&
    #
    echo "Run Benchmark ($RUN3 posts)" &&
    ./run.sh "$TEST_NAME" raw_results.md append &&
    #
    dart extract_results.dart raw_results.md verbose &&
    if [ -n "$GIT_PAT" ]; then

        echo "Creating Pull Request" &&
            git config --global user.email "$GIT_EMAIL" &&
            git config --global user.name "$GIT_USER" &&
            echo "Creating new branch" &&
            git checkout -b results &&
            echo "Adding new files" &&
            git add raw_results.md readme.md &&
            git commit -m "Update results" &&
            echo "Pushing to new branch" &&
            echo "$GIT_PAT" >/app/token.txt && gh auth login --with-token </app/token.txt &&
            git push --force https://$(echo "$GIT_USER:$GIT_PAT")@github.com/$(git config --get remote.origin.url | cut -d'/' -f4-5) results &&
            gh pr create --title "[SKIP] Update Benchmark Results ($DEVICE)" --body "Automated PR" --base main --head results &&
            echo "Done"
    else
        echo "No GIT_PAT provided, skipping PR creation"
    fi
