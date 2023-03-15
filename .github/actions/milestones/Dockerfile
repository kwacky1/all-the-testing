FROM alpine
RUN apk update && apk add ruby ruby-dev ruby-etc build-base && gem install json && gem install bigdecimal && gem install octokit -v 4.15.0 && gem install activesupport && gem install tzinfo-data
COPY . /
CMD ["ruby", "/milestones.rb"]
