export const showProgress = () => {
    // Progress Bar Variables
    const progressContainer = document.querySelectorAll(".js-progress-container");
    const progressContainerWidth = progressContainer.offsetWidth;

    const progressDivs = document.querySelectorAll(".progress")


  progressDivs.forEach(progressDiv => {
    //// Access to campaigns!!

    // console.log(progressDiv.dataset.campaigns)
    // console.log("progressDiv", progressDiv)

    let progress = progressDiv.querySelector(".js-progress")
    let progressWidth = progress.offsetWidth;

    // here you can set the actual progress (progressWidth)!!
      // progressWidth = 50
      progressWidth = progressDiv.dataset.campaigns.length + 25

      // different colors for progress!!
      if(progressWidth >= 25){
          progress.classList.add("tracker-progress-green");
      } else {
          progress.classList.remove("tracker-progress-green");
      }
      progress.style.width = progressWidth + "%";
  })
}

