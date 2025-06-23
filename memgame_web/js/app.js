Telegram.WebApp.ready();
let init_data = Telegram.WebApp.initData

let api_url = "/"; // Используем относительные пути для API когда фронтенд интегрирован в Rails
//init_data = "user=%7B%22id%22%3A317600571%2C%22first_name%22%3A%22%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80%22%2C%22last_name%22%3A%22%22%2C%22username%22%3A%22aleksandrrr_n%22%2C%22language_code%22%3A%22ru%22%2C%22is_premium%22%3Atrue%2C%22allows_write_to_pm%22%3Atrue%2C%22photo_url%22%3A%22https%3A%5C%2F%5C%2Ft.me%5C%2Fi%5C%2Fuserpic%5C%2F320%5C%2FlcHASOH7fiK4aSZX9v9XBudEdIE7m91wkR957a1XpZs.svg%22%7D&chat_instance=-7090027097801552795&chat_type=channel&auth_date=1736270286&signature=VTQpsQKQrOuHEX-Z6KVDT81nmHxDBeYiJXoo47PLTdZfk0z4hdneRFl3ITwjZGAfm8CSWfgiKtLARchvv5fpCg&hash=29fba79d9b9a8ec4393469d47b0a5c08d9f93958ca226c81dcd521d9892ee55b"

console.log("🎮 window.location.href32 ", window.location.href)

if (window.location.href.includes("127.0.0.1:5500")) {
  // Если запущен отдельно через webpack dev server
  api_url = "http://127.0.0.1:3000/";
  init_data = "user=%7B%22id%22%3A317600571%2C%22first_name%22%3A%22%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80%22%2C%22last_name%22%3A%22%22%2C%22username%22%3A%22aleksandrrr_n%22%2C%22language_code%22%3A%22ru%22%2C%22is_premium%22%3Atrue%2C%22allows_write_to_pm%22%3Atrue%2C%22photo_url%22%3A%22https%3A%5C%2F%5C%2Ft.me%5C%2Fi%5C%2Fuserpic%5C%2F320%5C%2FlcHASOH7fiK4aSZX9v9XBudEdIE7m91wkR957a1XpZs.svg%22%7D&chat_instance=-7090027097801552795&chat_type=channel&auth_date=1736270286&signature=VTQpsQKQrOuHEX-Z6KVDT81nmHxDBeYiJXoo47PLTdZfk0z4hdneRFl3ITwjZGAfm8CSWfgiKtLARchvv5fpCg&hash=29fba79d9b9a8ec4393469d47b0a5c08d9f93958ca226c81dcd521d9892ee55b"
} else if (window.location.href.includes("memgame-api.fly.dev")) {
  // Если запущен на production сервере fly.dev
  api_url = "https://memgame-api.fly.dev/";
}
 


// Init TWA
 

let timeout_game_wait  = null
let timeout_round_wait = null
let timeout_vote_wait = null
let timeout_restart_wait  = null

let data_game = null
let data_round = null
let user_id = null
let div_my_mems = document.getElementById('div_my_mems')
let user_data = null


const avatars = [
  1,2,10,11,13,15,17,20,29,32,37,42,43,50,51,
  54,57,62,70,75,
  77,85,88,105,114
 ]
function setBaseAvatars(){
  const container = document.getElementById("container_avatars")
  let html = ""
  avatars.forEach(avatar => {
    html += `<img data-name="${avatar}" src="/assets/mem_img/svg/mem_${avatar}.svg"/>`
  })

  container.innerHTML = html

  Array.from(container.querySelectorAll("img")).forEach(element => {
    element.addEventListener("click", setNewAvatar)
  })

  function setNewAvatar(){
    Array.from(container.querySelectorAll("img")).forEach(element => {
      element.classList.remove("selected")
    })
    this.classList.add("selected")
  }
}
setBaseAvatars()

document.getElementById('div_user_info').addEventListener('click', function(){
  const user_data = document.getElementById('container_user_data')
  if (user_data.style.display === "block") {
    user_data.style.display = "none"
  } else {
    user_data.style.display = "block"
  }

})
document.getElementById('btn_save_user_data').addEventListener('click', function(){
  let ava = ""
  let name = document.getElementById("input_user_nick").value


  const container = document.getElementById("container_avatars")
  Array.from(container.querySelectorAll("img")).forEach(element => {
    if (element.classList.contains("selected") ) {
      ava = element.getAttribute("data-name")
    }
  })

  if (name === "") {
    showAlert('good', "Введите ник")
    return
  }
  if (ava === "") {
    alert("Выберите аватар")
    return
  }

  sendRequest('post', 'save_user_data', {name: name, ava: ava})
    .then(data => {
      setUserData(data.user)
      document.getElementById('container_user_data').style.display = "none"
    })
    .catch(err => console.log(err))
})
const btn_click_energy = document.getElementById('btn_click_energy')


function getUserData(){
  sendRequest('post', 'get_user_data', {})
    .then(data => {
      document.getElementById("page_load").style.display = "none"
      document.getElementById("page_main").style.display = "block"

      user_data = data.user
      setUserData(data.user)
      setClickerImg()

      document.querySelector('[data-page="main"] .big_img').src = "assets/mem_img/gif/mem_20.gif"
      document.querySelector('[data-page="friends"] .big_img').src = "assets/mem_img/gif/mem_98.gif"
      document.querySelector('[data-page="tournament"] .big_img').src = "assets/mem_img/gif/mem_75.gif"
      document.querySelector('[data-page="clicker"] .big_img').src = "assets/mem_img/gif/mem_41.gif"

      document.querySelector('#container_error .container_big_img img').src = "assets/mem_img/gif/mem_57.gif"
      document.querySelector('#container_premium .container_big_img img').src = "assets/mem_img/gif/mem_14.gif"
      document.querySelector('#container_finish_game .big_img').src = "assets/mem_img/gif/mem_1.gif"

      getUserFriends()
    })
    .catch(err => console.log(err))
}
getUserData()

function setUserData(user){
  user_data = user
  document.getElementById("user_name").innerText = user.name
  document.getElementById("user_ava").src = `/assets/mem_img/svg/mem_${user.ava}.svg`
  document.getElementById("input_user_nick").value = user.name
  document.querySelectorAll('.value_coins').forEach(e => { e.innerText = user.coins})
  document.getElementById("current_dollars").innerText = `~${(user.coins * 4.06).toFixed(2)}$`

  setEnergy(user.energy)

  if (user.premium){
    document.querySelectorAll('.open_premium').forEach(e => { e.style.display = 'none'})
  
    document.querySelectorAll('.text_cost_participant').forEach(e => { e.innerText = 'За участие +30'})
    document.querySelectorAll('.text_cost_winner').forEach(e => { e.innerText = 'За участие +150'})
  }

  if (user.registered_in_tournament) {
    document.getElementById('btn_tournament_register').style.display = 'none'
    document.getElementById('div_tournament_registered').style.display = 'block'
  }
}

function getUserFriends(){

  sendRequest('post', 'get_user_friends', {})
    .then(data => {

      if (data.friends.length > 0){
        setUserFriends(data.friends)
      }
    })
    .catch(err => console.log(err))
}

function setUserFriends(friends) {
  let html = ''

  friends.forEach(friend => {
    html += `
      <div class="friend_item">
        <div class="base_info">
          <img src="assets/mem_img/svg/mem_${friend.ava}.svg" />
          <div>${friend.name}</div>
        </div>

        <div class="second_info">
          <div class="container text_with_icon">+500 <img src="img/coin.svg"/></div>

          <div class="date">${friend.date}</div>
        </div>
      </div>
    `
  })

  document.getElementById('div_friends_list').innerHTML = html
}


const GAME_COST = 75
function setEnergy(energy) {
  let energy_text = parseFloat(energy).toFixed(1)
  if (energy_text > user_data.energy_max) { energy_text = user_data.energy_max }
  document.querySelectorAll('.value_energy').forEach(e => { e.innerText = energy_text })
  document.querySelectorAll('.top_bar .value_energy').forEach(e => { e.innerText = parseInt(energy_text) })


  let energy_percent = 100 * energy/user_data.energy_max
  if (energy_percent > 100) { energy_percent = 100 }
  document.querySelectorAll('.top_bar .energy_bar').forEach(e => e.style.width = `${energy_percent}%`)


  let energy_int = energy_text
  if (energy_int == user_data.energy_max) { energy_int -= 0.001 }
  let game_percent = 100 * ( energy_int % GAME_COST) / GAME_COST
  document.querySelectorAll('[data-page="clicker"] .energy_bar').forEach(e => e.style.width = `${game_percent}%`)


  let games_num = parseInt(parseInt(energy_text) / GAME_COST)
  let games_text = 'игр'
  document.getElementById('text_games_count').innerText = `${games_num} ${games_text}`


  //let game_percent_full = parseInt(100 * ( parseInt(energy_text) % GAME_COST) / GAME_COST)
  //if (game_percent_full == 0) {game_percent_full = 100} 
  //document.getElementById('energy_game_percent').innerText = `${game_percent_full}%`
}


document.getElementById('btn_invite_friend').addEventListener('click', function(){
  document.getElementById('btn_invite_friend').style.display = 'none'
  document.getElementById('div_btns_invite').style.display = 'block'
})

document.getElementById('btn_invite_message').addEventListener('click', function(){
  sendRequest('post', 'create_tg_message')
    .then(data => {
      Telegram.WebApp.shareMessage(data.message.result.id)
    })
    .catch(err => console.log(err))
})

document.getElementById('btn_invite_link').addEventListener('click', function(){
  navigator.clipboard.writeText(`https://t.me/mem_culture_bot?start=in_${user_data.tg_id}`);
  
  document.getElementById('btn_invite_link').innerText = 'Скопирована!'
})
  


Telegram.WebApp.expand();

const UPDATE_TIME = 1000;
eruda.init()
let logger = eruda.get('console');

function showUserInfo(){
  logger.log('eruda');
  logger.log("initData ", Telegram.WebApp.initData)
  logger.log("initDataUnsafe ", Telegram.WebApp.initDataUnsafe)
  logger.log("initData user ", Telegram.WebApp.initDataUnsafe.user)

  logger.log("href ", window.location.href)
  logger.log("WebAppInitData1 ", Telegram.WebAppInitData)
  logger.log("WebAppInitData2 ", Telegram.webAppInitData)
  logger.log("WebAppInitData3 ", Telegram.webAppInitDataUnsafe)
  logger.log("WebView ", Telegram.WebView)
  logger.log("Telegram ", Telegram)

  
}
showUserInfo()


const div_video = document.getElementById("div_video")
const my_mem_video = document.getElementById("my_mem_video")
const my_mem_mp4 = document.getElementById("my_mem_mp4")

const container_game_participants = document.getElementById("container_game_participants")
document.getElementById('btn_create').addEventListener('click', function(){
  document.getElementById('btn_enter').style.display = 'none'
  document.getElementById(`container_finish_game`).style.display = "none"

  game_question.innerText = "Ожидаем игроков..."
  progress_comment.innerText = ""
  container_progress_line.style.display = 'none'
  progress_line.style.width = "0%"

  if (container_game_participants.style.display == "block") {
    sendRequest('post', 'create_game', {participants: parseInt(game_participants.innerText)})
      .then(data => {
        if (data.error) {
          showAlert('bad', data.error)
          return
        }

        document.getElementById('page_main').style.display = "none"
        document.getElementById('page_game').style.display = "block"
        document.getElementById('game_question').innerText = `Отправьте друзьям код ${data.game.uniq_id} для присоединения к игре`
        div_my_mems.innerHTML = ""
        div_my_mems.style.display = "none"

        data_game = data.game
        user_id = data.user_id

        timeoutGameWait()
      })
      .catch(err => console.log(err))
  } else {
    document.getElementById("container_game_participants").style.display = "block"
  }
})

const game_participants = document.getElementById('game_participants')
document.getElementById('btn_add_participant').addEventListener('click', function(){
  let new_participants = parseInt(game_participants.innerText) + 1
  if (new_participants <= 5){
    game_participants.innerText = new_participants
  }
})
document.getElementById('btn_remove_participant').addEventListener('click', function(){
  let new_participants = parseInt(game_participants.innerText) - 1
  if (new_participants >= 3){
    game_participants.innerText = new_participants
  }
})


function showAlert(type, text){
  document.getElementById('container_error').style.display = 'block'
  document.getElementById('error_text').innerText = text

  if (type == 'good') {
    document.querySelector('#container_error img').src = 'assets/mem_img/gif/mem_11.gif'
  } else {
    document.querySelector('#container_error img').src = 'assets/mem_img/gif/mem_57.gif'
  }
}

const input_game_code = document.getElementById("input_game_code")

document.getElementById('btn_enter').addEventListener('click', function(){
  document.getElementById('btn_create').style.display = 'none'
  
  const game_code = parseInt(input_game_code.value)
  console.log("game_code ", game_code)

  if (game_code === 0 || game_code === null || game_code === undefined || isNaN(game_code)) {
    document.getElementById("container_game_code").style.display = "block"
  } else {
    sendRequest('post', 'join_to_game', {game_code: game_code})
      .then(data => {
        if (data.error) {
          showAlert('bad', data.error)
          return
        }

        document.getElementById('page_main').style.display = "none"
        document.getElementById('page_game').style.display = "block"
        document.getElementById(`btn_restart_game`).style.display = "none"

        div_my_mems.style.display = "none"

        data_game = data.game
        user_id = data.user_id

        timeoutGameWait()
      })
      .catch(err => console.log(err))
  }

})




document.getElementById('btn_new_game').addEventListener('click', function(){
  findGame()
})

document.getElementById('btn_find_game').addEventListener('click', function(){
  //showAlert('good', "Бета-тест. Доступна только игра между друзьями")
  //return

  document.getElementById(`container_finish_game`).style.display = "none"

  game_question.innerText = "Ожидаем игроков..."
  progress_comment.innerText = ""
  progress_line.style.width = "0%"
  container_progress_line.style.display = 'none'

  findGame()
})

function findGame(){
  sendRequest('post', 'find_game', {participants: parseInt(game_participants.innerText)})
    .then(data => {
      if (data.error){
        showAlert('bad', data.error)
        return
      }

      startGame(data.game, data.user_id)
    })
    .catch(err => console.log(err))
}

function startGame(game, current_user_id){
  document.getElementById(`container_finish_game`).style.display = "none"

  game_question.innerText = "Ожидаем игроков..."
  progress_comment.innerText = ""
  progress_line.style.width = "0%"
  container_progress_line.style.display = 'none'

  document.getElementById('game_winner').style.display = "none"
  document.getElementById('page_main').style.display = "none"
  document.getElementById('page_game').style.display = "block"
  div_my_mems.style.display = "none"

  data_game = game
  user_id = current_user_id

  timeoutGameWait()
}

function timeoutGameWait(){
  if (timeout_game_wait != null){
    clearInterval(timeout_game_wait)
  }

  setGameUsers([])

  timeout_game_wait = setInterval(() => {
    sendRequest('post', 'get_update_game_ready', {game_id: data_game.id})
      .then(data => {
        console.log("🎮 get_update_game_ready ", data)
        setGameUsers(data.users)
        setUsersReady(data.game, data.users)

        if (data.ready_to_start) {
          setTimeout(() => {
            div_my_mems.style.display = "flex"
          }, 550)

          clearInterval(timeout_game_wait)

          //document.getElementById("div_round_result").display = "block"
          //Array.from(document.getElementsByClassName("div_mem")).forEach(element => {
          //  element.style.display = "flex"
          //})
          timeoutRoundWait()
        }
      })
      .catch(err => console.log(err))
  }, UPDATE_TIME)
}

function setGameUsers(users){
  let html = ""

  users.forEach(user => {
    let game_points  = user.game_points

    html += `<div class="div_player" data-id="${user.game_user_number}">
                <div class="user_points">${game_points}<span class="new_points"></span></div>
                <img src="/assets/mem_img/svg/mem_${user.user_ava}.svg"/>
                <div class="user_name">${cutString( user.user_name, 10) }</div>
              </div>`
  })

  if (users.length < data_game.participants){
    for(let i = 0; i < data_game.participants - users.length; i++){
      html += `<div class="div_player">
                  <div class="user_points">&#8203;</div>
                  <img src="/assets/square.svg"/>
                  <div class="user_name">&#8203;</div>
                </div>`
    }
  }

  document.getElementById("div_players").innerHTML = html
}

function leaveGame(users){
  user_in_game = false
  users.forEach(user => {
    if (user.user_id == user_id){
      user_in_game = true
    }
  })
  if (!user_in_game){
    window.location.reload()
  }
}

function setUsersReady(game, users){
  const div_players = document.getElementById("div_players")

  users.forEach(user => {
    const container = div_players.querySelector(`.div_player[data-id="${user.game_user_number}"]`)
    container.classList.remove("winner")
  })
}

function setUsersRestart(game, users) {
  const div_players = document.getElementById("div_players")

  users.forEach(user => {
    if (user.ready_to_restart){
      const container = div_players.querySelector(`.div_player[data-id="${user.game_user_number}"]`)

      container.querySelector('.user_points').innerText = 'Готов'
    }
  })
}


const game_question = document.getElementById("game_question")
const progress_line = document.getElementById("progress_line")
const container_progress_line = document.getElementById("container_progress_line")

function cutString(str, length) {
  let result = str
  if (result.length > length) {
    result = str.slice(0, length) + "..."
  }

  return result
}


const progress_comment = document.getElementById("progress_comment")

function timeoutRoundWait(){
  if (timeout_round_wait != null){
    clearInterval(timeout_round_wait)
  }
  progress_comment.innerText = "Ожидаем мемы..."

  timeout_round_wait = setInterval(() => {
    sendRequest('post', 'get_round_update', {game_id: data_game.id})
      .then(data => {
        console.log("get_round_update ", data)

        game_question.innerText = data.question
        //game_question.innerText = ""
        if (data.round_progress_wait > 95) {
          //typeText(game_question, data.question)
        }

        progress_line.style.width = data.round_progress_wait + "%"
        container_progress_line.style.display = 'block'
        leaveGame(data.users)
        setGameUsers(data.users)
        setMyMems(data.my_mems)

        if (data.ready_to_open) {
          data_round = data.round
          clearInterval(timeout_round_wait)
          round_result = data.mems
          showRoundMems()
        }

      })
      .catch(err => console.log(err))
  }, UPDATE_TIME)
}

function typeText(element, text) {
  let speed = 50
  let i = 0
  element.innerHTML = ""

  function typeWritter() {
    if (i < text.length) {
      element.innerHTML += text.charAt(i);
      i++;
      setTimeout(typeWritter, speed);
    }
  }

  typeWritter()
}

function setMyMems(my_mems){
  let html = ''
  my_mems.forEach(mem => {
    const in_active = mem.active ? "" : `<div class="mem_inactive"></div>`
    html += `<div class="mem_card" data-name="${mem.name}" data-active="${mem.active}"><img src="assets/mem_video/${mem.name}.png"/>${in_active}</div>`
  })

  document.getElementById('div_my_mems').innerHTML = html

  Array.from(document.querySelectorAll("#div_my_mems .mem_card")).forEach(function(element) {
    element.addEventListener("click", onMemClick )
  })
}

function onMemClick(){
  if (this.getAttribute("data-active") === "true") {
    const mem_name = this.getAttribute("data-name")
    div_video.style.display = "flex"
    my_mem_mp4.src = `assets/mem_video/${mem_name}.mp4`
    btn_send.innerText = "Отправить"
    btn_send.setAttribute("data-mem-name", mem_name)
    my_mem_video.load();
    my_mem_video.play();
  }
}

const btn_send = document.getElementById('btn_send')

btn_send.addEventListener('click', function(){
  const mem_name = this.getAttribute("data-mem-name")
  div_my_mems.style.display = "none"

  //div_video.style.display = "none"
  //my_mem_video.pause();

  sendRequest('post', 'send_round_mem', {game_id: data_game.id, mem_name: mem_name})
    .then(data => {

      Array.from(document.getElementsByClassName("div_mem")).forEach(element => {
        element.style.display = "none"
      })

      btn_send.innerText = "Ждём..."
    })
    .catch(err => console.log(err))
})


let round_result = [
  {name: "Name1", avatar: "avatar", mem: "zhestko"},
  {name: "Name2", avatar: "avatar", mem: "aeroflot"},
  {name: "Name3", avatar: "avatar", mem: "lavochka_zakrita"},
]


const div_video_0 = document.getElementById("div_video_0")
const mem_0_video = document.getElementById("mem_0_video")

const div_video_1 = document.getElementById("div_video_1")
const mem_1_video = document.getElementById("mem_1_video")

const div_video_2 = document.getElementById("div_video_2")
const mem_2_video = document.getElementById("mem_2_video")

const div_video_3 = document.getElementById("div_video_3")
const mem_3_video = document.getElementById("mem_3_video")

const div_video_4 = document.getElementById("div_video_4")
const mem_4_video = document.getElementById("mem_4_video")

mem_0_video.onended = function(e) {
  div_video_1.style.display = "flex"
  mem_1_video.load();
  mem_1_video.play();
};
mem_1_video.onended = function(e) {
  if (round_result.length > 2) {
    div_video_2.style.display = "flex"
    mem_2_video.load();
    mem_2_video.play();

  } else {
    showVotes()
  }
};
mem_2_video.onended = function(e) {
  if (round_result.length > 3) {
    div_video_3.style.display = "flex"
    mem_3_video.load();
    mem_3_video.play();
  } else {
    showVotes()
  }

};
mem_3_video.onended = function(e) {
  if (round_result.length > 4) {
    div_video_4.style.display = "flex"
    mem_4_video.load();
    mem_4_video.play();
  } else {
    showVotes()
  }

};
mem_4_video.onended = function(e) {
  showVotes()

};

function showVotes(){
  round_result.forEach((item, i) => {
    const container = document.getElementById(`div_video_${i}`)
    //container.querySelector('.votes_count').style.display = "block"
    container.querySelector('.mem_vote').style.display = "block"
    container.querySelector('.mem_vote').addEventListener("click", voteForMem)
  })

  sendRequest('post', 'start_voting', {game_id: data_game.id, round_id: data_round.id})
    .then(data => {  })
    .catch(err => console.log(err))

  timeoutVotesWait()
}

function voteForMem(){
  Array.from(document.querySelectorAll(".mem_vote")).forEach(element => {
    element.style.visibility = "hidden"
  })

  this.parentElement.parentElement.querySelector('.container_video_mem').classList.add('voted')

  const user_num = this.getAttribute("data-user-num")
  console.log("voteForMem ", user_num)

  sendRequest('post', 'vote_for_mem', {user_num: user_num, round_id: data_round.id})
    .then(data => {
    })
    .catch(err => console.log(err))
}

function timeoutVotesWait(){
  console.log("Wait for vote")
  if (timeout_vote_wait != null){
    clearInterval(timeout_vote_wait)
  }
  progress_comment.innerText = "Голосуем..."

  timeout_vote_wait = setInterval(() => {
    sendRequest('post', 'get_vote_update', {game_id: data_game.id})
      .then(data => {
        console.log("get_vote_update ", data)
       // setGameUsers(data.users)
        setVotes(data.mems)
        progress_line.style.width = data.vote_progress_wait + "%"
        container_progress_line.style.display = 'block'
        leaveGame(data.users)

        if (data.vote_finish) {
          clearInterval(timeout_vote_wait)
          setGameUsers(data.users)

          if (data.finish_game){
            finishGame()
          } else {
            finishRound()
          }
        }
      })
      .catch(err => console.log(err))
  }, UPDATE_TIME)
}

function setVotes(data){
  const container = document.getElementById(`div_round_result`)

  //data.forEach(item => {
  //  container.querySelector(`.votes_count[data-user-num="${item.user_num}"]`).innerHTML = item.votes
  //})

  const players = document.getElementById(`div_players`)
  data.forEach(item => {
    if (item.votes > 0){
      players.querySelector(`.div_player[data-id="${item.user_num}"] .new_points`).innerText = `+${item.votes}`
    }
  })

}



function finishRound(){
  div_my_mems.style.display = "flex"

  Array.from(document.getElementsByClassName("div_mem")).forEach(element => {
    element.style.display = "none"
  })

  Array.from(document.getElementsByClassName("container_video_mem")).forEach(element => {
    element.classList.remove('voted')
  })

  window.scrollTo(0, 0)

  timeoutRoundWait()
}

function finishGame(){
  document.getElementById(`div_question`).style.display = "none"
  document.getElementById(`div_round_result`).style.display = "none"

  sendRequest('post', 'get_game_winner', {game_id: data_game.id})
    .then(data => {
      setGameUsers(data.users)

      data.winners_ids.forEach(id => {
        document.querySelector(`.div_player[data-id="${id}"]`).classList.add("winner")
      })

      document.getElementById(`div_question`).style.display = "block"
      document.getElementById(`game_question`).innerText = "Еще игру?"

      document.getElementById(`container_finish_game`).style.display = "block"

      document.getElementById(`game_winner`).style.display = "block"
      document.getElementById(`game_winner`).innerText= `Победитель ${data.winners_names}`

      timeoutRestartWait()
    })
    .catch(err => console.log(err))
}

document.getElementById('btn_restart_game').addEventListener('click', function(){
  document.getElementById(`container_finish_game`).style.display = "none"

  document.getElementById(`game_question`).innerText = "Ожидаем решения остальных..."
  
  sendRequest('post', 'ready_to_restart', {game_id: data_game.id})
    .then(data => {
      if (data.error) {
        showAlert('bad', data.error)
      }
      
    })
    .catch(err => console.log(err))
})

function timeoutRestartWait(){
  if (timeout_restart_wait != null){
    clearInterval(timeout_restart_wait)
  }


  timeout_restart_wait = setInterval(() => {
    sendRequest('post', 'get_restart_update', {game_id: data_game.id})
      .then(data => {
        console.log("get_restart_update ", data)
        progress_line.style.width = data.restart_progress_wait + "%"
        container_progress_line.style.display = 'block'

        setGameUsers(data.users)
        setUsersRestart(data.game, data.users)

        data.winners_ids.forEach(id => {
          document.querySelector(`.div_player[data-id="${id}"]`).classList.add("winner")
        })

        if (data.ready_to_start) {
          clearInterval(timeout_restart_wait)

          if (data_game.id == data.new_game.id) {
            window.location.reload()
          } else {
            startGame(data.new_game, data.user_id)
          }
        }
      })
      .catch(err => console.log(err))
  }, UPDATE_TIME)
}



function showRoundMems(){
  Array.from(document.getElementsByClassName("container_video_mem")).forEach(element => {
    element.classList.remove('voted')
  })

  progress_comment.innerText = ""
  progress_line.style.width = "0%"
  container_progress_line.style.display = 'none'

  my_mem_video.pause();
  div_video.style.display = "none"
  document.getElementById("div_round_result").style.display = "block"
  div_my_mems.style.display = "none"

  round_result.forEach((item, i) => {
    const container = document.getElementById(`div_video_${i}`)
    container.querySelector('.mem_sender_name').innerText = item.name
    container.querySelector('.user_avatar').src = `/assets/mem_img/svg/mem_${item.avatar}.svg`
    container.querySelector('source').src = `assets/mem_video/${item.mem}.mp4`

    //container.querySelector('.votes_count').innerText = 0
    //container.querySelector('.votes_count').setAttribute("data-user-num", item.user_num)
    //container.querySelector('.votes_count').style.display = "none"
    container.querySelector('.mem_vote').style.display = "none"
    container.querySelector('.mem_vote').style.visibility = "visible"
    container.querySelector('.mem_vote').setAttribute("data-user-num", item.user_num)

    container.classList.remove("my")
    if (item.user_id === user_id){
      container.classList.add("my")
      container.querySelector('.mem_vote').style.visibility = "hidden"
    }
   // document.getElementById(`mem_${i}_mp4`).src = `mems/${item.mem}.mp4`
  })

  div_video_0.style.display = "flex"
  mem_0_video.load()
  mem_0_video.play()
}


let timeout_click = null
let clicks = 1
btn_click_energy.addEventListener('click', function(){
  user_data.energy += user_data.premium ? 1.1 : 0.1
  setEnergy(user_data.energy)

  if (timeout_click != null) {
    clearTimeout(timeout_click)
  }

  clicks += 1
  if (clicks % 25 == 0) {
    setClickerImg()
  }
  
  timeout_click = setTimeout(() => {

    sendRequest('post', 'update_energy', { energy: user_data.energy })
    .then(data => {
      user_data.energy = data.energy
      setEnergy(user_data.energy)
    })
    .catch(err => console.log(err))
  }, 500);
})

function setClickerImg(){
  const img_num = getRandomInt(1, 114)
  btn_click_energy.src = `assets/mem_img/svg/mem_${img_num}.svg`
}
function getRandomInt(min, max) {
  const minCeiled = Math.ceil(min);
  const maxFloored = Math.floor(max);
  return Math.floor(Math.random() * (maxFloored - minCeiled) + minCeiled); // The maximum is exclusive and the minimum is inclusive
}



document.querySelectorAll('.nav_bottom').forEach(e => e.addEventListener('click', onClickNavigation));

function onClickNavigation(){
  const new_page = this.getAttribute('data-page')
 
  document.querySelectorAll('.page_main').forEach(e => e.style.display = 'none');
  document.querySelectorAll('.nav_bottom').forEach(e => e.classList.remove('active'));

  document.querySelector(`.page_main[data-page="${new_page}"]`).style.display = 'flex';
  document.querySelector(`.nav_bottom[data-page="${new_page}"]`).classList.add('active');
  document.body.scrollTo(0, 0)

  document.querySelectorAll('.nav_bottom img').forEach(e => {
    const img_name = e.parentElement.parentElement.getAttribute('data-page')

    const folder = new_page == img_name ? `selected` : `common`
    e.src = `./img/nav/${folder}/${img_name}.svg`
  });
}




document.getElementById('btn_tournament_register').addEventListener('click', () => {

  sendRequest('post', 'register_in_tournament')
    .then(data => {
      if (data.error) {
        showAlert('bad', data.error);
        return
      }

      setUserData(data.user)
    })
    .catch(err => console.log(err))
})





document.getElementById('btn_buy_premium').addEventListener('click', () => {
  sendRequest('post', 'get_payment_link')
    .then(data => {
      Telegram.WebApp.openInvoice(data.link)
    })
    .catch(err => console.log(err))
})

Telegram.WebApp.onEvent('invoiceClosed', function(responce) {
  if (responce.status == 'paid') {
    showAlert('good', `Премиум активируется в течении 2х минут`)
  }
});



document.querySelectorAll('.open_premium').forEach(e => e.addEventListener('click', onClickPremium));
function onClickPremium(){
  document.getElementById('container_premium').style.display = 'block'
}


document.querySelectorAll('.bottom_container .background').forEach(e => e.addEventListener('click', onClickBackground));
function onClickBackground(){
  document.querySelectorAll('.bottom_container').forEach(e => e.style.display = 'none');
}

document.getElementById('btn_close_error').addEventListener('click', () => {
  onClickBackground()
})



document.getElementById('current_dollars').addEventListener('click', () => {
  showAlert('good', 'Расчетная стоимость ваших монет на момент листинга')
})

drawChart()
function drawChart() {
  const labels = ['14.01', '30.01', '14.02', '28.02', '14.03', '30.03', '15.04', '30.04',  '15.05', '30.05',  '15.06', '30.06' ];
  const data = {
    labels: labels,
    datasets: [
      {
        label: 'Цена',
        data: [0.05, 0.10, 0.3, 0.5, 0.8, 1, 1.1, 1.3, 1.6, 2, 2.7, 4.1],
        borderColor: '#FF7F5C',
        backgroundColor: '#FF7F5C',
      }
    ]
  }

  const config = {
    type: 'line',
    data: data,
    options: {
      responsive: true,
      plugins: {
        legend: {
          display: false,
        }
      },

      animations: {
        tension: {
          duration: 1000,
          easing: 'linear',
          from: 1,
          to: 0,
          loop: true
        }
      },
    },
  };


  const ctx = document.getElementById('profit_graph')
  const myChart = new Chart(ctx, config);

}



document.getElementById('btn_converter').addEventListener('click', () => {
  sendRequest('post', 'convert_energy')
    .then(data => {
      if (data.error){
        showAlert('bad', data.error)
        return
      }
      clicks = 0

      setUserData(data.user)
    })
    .catch(err => console.log(err))

})


function sendRequest(type, url, body = null) {

  const headers = {
    'Content-type': 'application/json',
    'TelegramData': init_data
  }

  return fetch(`${api_url}${url}`, {
    method: type,
    body: JSON.stringify(body),
    headers: headers
  }).then(response => {
    return response.json()
  })
}


function setCookie(name, value, days = 1600) {
  var expires = "";
  if (days) {
    var date = new Date();
    date.setTime(date.getTime() + (days*24*60*60*1000));
    expires = "; expires=" + date.toUTCString();
  }
  document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}
function getCookie(name) {
  var matches = document.cookie.match(new RegExp(
    "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
  ));
  return matches ? decodeURIComponent(matches[1]) : undefined;
}

function deleteCookie( name ) {
  document.cookie = name + '=undefined; expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/';
}

