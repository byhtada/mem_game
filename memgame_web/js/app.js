// 🚀 Версия с автоматическим watcher
Telegram.WebApp.ready();
let init_data = Telegram.WebApp.initData

let api_url = "/"; // Используем относительные пути для API когда фронтенд интегрирован в Rails
//init_data = "user=%7B%22id%22%3A317600571%2C%22first_name%22%3A%22%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80%22%2C%22last_name%22%3A%22%22%2C%22username%22%3A%22aleksandrrr_n%22%2C%22language_code%22%3A%22ru%22%2C%22is_premium%22%3Atrue%2C%22allows_write_to_pm%22%3Atrue%2C%22photo_url%22%3A%22https%3A%5C%2F%5C%2Ft.me%5C%2Fi%5C%2Fuserpic%5C%2F320%5C%2FlcHASOH7fiK4aSZX9v9XBudEdIE7m91wkR957a1XpZs.svg%22%7D&chat_instance=-7090027097801552795&chat_type=channel&auth_date=1736270286&signature=VTQpsQKQrOuHEX-Z6KVDT81nmHxDBeYiJXoo47PLTdZfk0z4hdneRFl3ITwjZGAfm8CSWfgiKtLARchvv5fpCg&hash=29fba79d9b9a8ec4393469d47b0a5c08d9f93958ca226c81dcd521d9892ee55b"

console.log("🎮 window.location.href323 ", window.location.href)

if (window.location.href.includes("localhost:3000")) {
  init_data = "user=%7B%22id%22%3A317600571%2C%22first_name%22%3A%22%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80%22%2C%22last_name%22%3A%22%22%2C%22username%22%3A%22aleksandrrr_n%22%2C%22language_code%22%3A%22ru%22%2C%22is_premium%22%3Atrue%2C%22allows_write_to_pm%22%3Atrue%2C%22photo_url%22%3A%22https%3A%5C%2F%5C%2Ft.me%5C%2Fi%5C%2Fuserpic%5C%2F320%5C%2FlcHASOH7fiK4aSZX9v9XBudEdIE7m91wkR957a1XpZs.svg%22%7D&chat_instance=-7090027097801552795&chat_type=channel&auth_date=1736270286&signature=VTQpsQKQrOuHEX-Z6KVDT81nmHxDBeYiJXoo47PLTdZfk0z4hdneRFl3ITwjZGAfm8CSWfgiKtLARchvv5fpCg&hash=29fba79d9b9a8ec4393469d47b0a5c08d9f93958ca226c81dcd521d9892ee55b"
} else if (window.location.href.includes("teremok.space")) {
  init_data = Telegram.WebApp.initData
}
 


// Init TWA
 

let timeout_game_wait  = null
let timeout_round_wait = null
let timeout_round_left_ms = 0

let timeout_vote_wait = null
let timeout_vote_left_ms = 0

let timeout_restart_wait  = null
let timeout_restart_left_ms = 0

let data_game = null
let data_round = null
let user_id = null
let div_my_mems = document.getElementById('div_my_mems')
let user_data = null
let constants = null

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
      constants = data.constants
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

// WebSocket переменные для управления подписками
let gameSubscription = null;
let roundSubscription = null;
let voteSubscription = null;
let restartSubscription = null;
let newGameSubscription = null;
let isWebSocketsEnabled = true; // Флаг для включения/отключения веб-сокетов

// Обработчики для отключения веб-сокетов при уходе со страницы
window.addEventListener('beforeunload', () => {
  disconnectWebSocket()
})

// При изменении видимости страницы (переключение вкладок)
document.addEventListener('visibilitychange', () => {
  return
  if (document.hidden) {
    // Страница скрыта - отключаем веб-сокеты для экономии ресурсов
    if (gameSubscription) {
      console.log('🔄 [visibilitychange] Page hidden - unsubscribing from game channel')
      gameSubscription.unsubscribe()
      gameSubscription = null
    }
    if (roundSubscription) {
      console.log('🔄 [visibilitychange] Page hidden - unsubscribing from round channel')
      roundSubscription.unsubscribe()
      roundSubscription = null
    }
    if (voteSubscription) {
      console.log('🔄 [visibilitychange] Page hidden - unsubscribing from vote channel')
      voteSubscription.unsubscribe()
      voteSubscription = null
    }
  } else {
    // Страница снова видима - переподключаемся если нужно
    console.log('🔄 [visibilitychange] Page visible - checking if reconnection needed')
    console.log('🔄 [visibilitychange] WebSockets enabled:', isWebSocketsEnabled)
    console.log('🔄 [visibilitychange] Game data exists:', !!data_game?.id)
      console.log('🔄 [visibilitychange] Game subscription exists:', !!gameSubscription)
  console.log('🔄 [visibilitychange] Round subscription exists:', !!roundSubscription)
  console.log('🔄 [visibilitychange] Vote subscription exists:', !!voteSubscription)
  console.log('🔄 [visibilitychange] Restart subscription exists:', !!restartSubscription)
    console.log('🔄 [visibilitychange] Cable connection state:', actionCableConsumer.cable?.readyState)
    
    // Переподключаемся только если нет активной подписки И нет активного соединения
    if (isWebSocketsEnabled && data_game && data_game.id && !gameSubscription && !roundSubscription && !voteSubscription && !restartSubscription && 
        (!actionCableConsumer.cable || actionCableConsumer.cable.readyState !== WebSocket.OPEN)) {
      console.log('🔄 [visibilitychange] Reconnection needed - scheduling reconnect')
      setTimeout(() => {
        // Переподключаемся к нужному типу обновлений в зависимости от состояния игры
        if (data_game.state === 'registration') {
          subscribeToGameUpdates()
        } else if (data_game.state === 'playing') {
          // Определяем нужный канал в зависимости от состояния раунда
          // TODO: добавить логику определения состояния раунда
          subscribeToRoundUpdates()
        }
      }, 1000)
    } else {
      console.log('🔄 [visibilitychange] Reconnection not needed - connection is active')
    }
  }
})

function disconnectWebSocket() {
  console.log('🔌 [disconnectWebSocket] Cleaning up WebSocket connections...');
  
  if (gameSubscription) {
    console.log('🔌 [disconnectWebSocket] Unsubscribing from game channel');
    gameSubscription.unsubscribe()
    gameSubscription = null
  }
  
  if (roundSubscription) {
    console.log('🔌 [disconnectWebSocket] Unsubscribing from round channel');
    roundSubscription.unsubscribe()
    roundSubscription = null
  }
  
  if (voteSubscription) {
    console.log('🔌 [disconnectWebSocket] Unsubscribing from vote channel');
    voteSubscription.unsubscribe()
    voteSubscription = null
  }
  
  if (restartSubscription) {
    console.log('🔌 [disconnectWebSocket] Unsubscribing from restart channel');
    restartSubscription.unsubscribe()
    restartSubscription = null
  }
  
  if (actionCableConsumer) {
    console.log('🔌 [disconnectWebSocket] Disconnecting Action Cable');
    actionCableConsumer.disconnect()
  }
  
  console.log('🔌 [disconnectWebSocket] Cleanup completed');
}
//eruda.init()
//let logger = eruda.get('console');

function showUserInfo(){
  //logger.log('eruda');
  //logger.log("initData ", Telegram.WebApp.initData)
  //logger.log("initDataUnsafe ", Telegram.WebApp.initDataUnsafe)
  //logger.log("initData user ", Telegram.WebApp.initDataUnsafe.user)
//
  //logger.log("href ", window.location.href)
  //logger.log("WebAppInitData1 ", Telegram.WebAppInitData)
  //logger.log("WebAppInitData2 ", Telegram.webAppInitData)
  //logger.log("WebAppInitData3 ", Telegram.webAppInitDataUnsafe)
  //logger.log("WebView ", Telegram.WebView)
  //logger.log("Telegram ", Telegram)

  
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
  // Отключаем старый polling если он был активен
  if (timeout_game_wait != null){
    clearInterval(timeout_game_wait)
  }

  setGameUsers([])

  // Используем веб-сокеты если они включены, иначе fallback к polling
  if (isWebSocketsEnabled) {
    subscribeToGameUpdates()
  } else {
    timeoutGameWaitPolling()
  }
}

// Новая функция для подписки на веб-сокет обновления игры
function subscribeToGameUpdates() {
  console.log("🔗 [subscribeToGameUpdates] Starting WebSocket connection for game updates...")
  console.log("🔗 [subscribeToGameUpdates] Game ID:", data_game?.id, "User ID:", user_id)
  
  // Проверяем наличие необходимых данных
  if (!data_game || !data_game.id) {
    console.error("❌ [subscribeToGameUpdates] No game data available");
    return;
  }
  
  if (!user_id) {
    console.error("❌ [subscribeToGameUpdates] No user_id available");
    return;
  }
  
  // Отписываемся от предыдущей подписки если она была
  if (gameSubscription) {
    console.log("🔗 [subscribeToGameUpdates] Unsubscribing from previous subscription")
    gameSubscription.unsubscribe()
    gameSubscription = null
  }

  // Включаем автоматическое переподключение
  actionCableConsumer.shouldReconnect = true;

  // Подключаемся к Action Cable
  console.log("🔗 [subscribeToGameUpdates] Connecting to Action Cable...")
  actionCableConsumer.connect('/cable', { user_id: user_id })

  // Создаем подписку на GameChannel
  console.log("🔗 [subscribeToGameUpdates] Creating subscription to GameChannel...")
  gameSubscription = actionCableConsumer.subscribe('GameChannel', {
    game_id: data_game.id
  })

  // Обработчики событий подписки
  gameSubscription.connected = () => {
    console.log("🎮 [subscribeToGameUpdates] ✅ Connected to game channel")
  }

  gameSubscription.disconnected = () => {
    console.log("❌ [subscribeToGameUpdates] Disconnected from game channel")
  }

  gameSubscription.received = (data) => {
    console.log("🎮 [subscribeToGameUpdates] WebSocket game update received:", data)
    handleGameUpdate(data)
  }
  
  console.log("🔗 [subscribeToGameUpdates] Subscription setup completed")
}

// Общая функция обработки обновлений игры (для веб-сокетов и polling)
function handleGameUpdate(data) {
  console.log("🎯 [handleGameUpdate] Processing game update:", data)
  console.log("🎯 [handleGameUpdate] Users count:", data.users?.length, "Ready to start:", data.ready_to_start)
  
  setGameUsers(data.users)
  setUsersReady(data.game, data.users)

  if (data.ready_to_start) {
    console.log("🎯 [handleGameUpdate] Game is ready to start! Starting game...")
    setTimeout(() => {
      div_my_mems.style.display = "flex"
      console.log("🎯 [handleGameUpdate] Showing mems selection")
    }, 550)

    // Отключаем обновления - игра началась
    if (gameSubscription) {
      console.log("🎯 [handleGameUpdate] Unsubscribing from game updates")
      gameSubscription.unsubscribe()
      gameSubscription = null
    }
    if (timeout_game_wait) {
      console.log("🎯 [handleGameUpdate] Clearing polling timeout")
      clearInterval(timeout_game_wait)
      timeout_game_wait = null
    }

    timeoutRoundWait()
  } else {
    console.log("🎯 [handleGameUpdate] Game not ready yet, continuing to wait...")
  }
}

function setGameUsers(users){
  let html = ""

  const currentUserIndex = users.findIndex(user => user.user_id === user_id)
  if (currentUserIndex > 0) {
    const currentUser = users.splice(currentUserIndex, 1)[0]
    users.unshift(currentUser)
  }

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

function setUsersRoundReady(users, round){
  const div_players = document.getElementById("div_players")

  users.forEach(user => {
    if (round[`mem_${user.game_user_number}_name`] != ""){
      const container = div_players.querySelector(`.div_player[data-id="${user.game_user_number}"]`)
      container.querySelector('.user_points').innerText = "Готов"
    }
  })
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

  setTimeout(() => {
    subscribeToRoundUpdates()
  }, 1000)
}

// Новая функция для подписки на веб-сокет обновления раунда
function subscribeToRoundUpdates() {
  console.log("🔗 [subscribeToRoundUpdates] Starting WebSocket connection for round updates...")
  console.log("🔗 [subscribeToRoundUpdates] Game ID:", data_game?.id, "User ID:", user_id)
  
  // Проверяем наличие необходимых данных
  if (!data_game || !data_game.id) {
    console.error("❌ [subscribeToRoundUpdates] No game data available");
    return;
  }
  
  if (!user_id) {
    console.error("❌ [subscribeToRoundUpdates] No user_id available");
    return;
  }
  
  // Отписываемся от предыдущей подписки если она была
  if (roundSubscription) {
    console.log("🔗 [subscribeToRoundUpdates] Unsubscribing from previous subscription")
    roundSubscription.unsubscribe()
    roundSubscription = null
  }

  // Включаем автоматическое переподключение
  actionCableConsumer.shouldReconnect = true;

  // Подключаемся к Action Cable
  console.log("🔗 [subscribeToRoundUpdates] Connecting to Action Cable...")
  actionCableConsumer.connect('/cable', { user_id: user_id })

  // Создаем подписку на RoundChannel
  console.log("🔗 [subscribeToRoundUpdates] Creating subscription to RoundChannel...")
  roundSubscription = actionCableConsumer.subscribe('RoundChannel', {
    game_id: data_game.id
  })

  // Обработчики событий подписки
  roundSubscription.connected = () => {
    console.log("🎮 [subscribeToRoundUpdates] ✅ Connected to round channel")
  }

  roundSubscription.disconnected = () => {
    console.log("❌ [subscribeToRoundUpdates] Disconnected from round channel")
  }

  roundSubscription.received = (data) => {
    console.log("🎮 [subscribeToRoundUpdates] WebSocket round update received:", data)
    handleRoundUpdate(data)
  }
  
  console.log("🔗 [subscribeToRoundUpdates] Subscription setup completed")
}

// Общий обработчик обновлений раунда (для WebSocket и polling)
function handleRoundUpdate(data) {
  game_question.innerText = data.question

  progress_line.style.width = data.round_progress_wait + "%"
  container_progress_line.style.display = 'block'
  leaveGame(data.users)
  setGameUsers(data.users)
  setUsersRoundReady(data.users, data.round)

  timeout_round_left_ms = data.round_progress_left
  setRoundProgressLeft()
  
  // my_mems приходят только при подписке, не в broadcast обновлениях
  if (data.my_mems) {
    setMyMems(data.my_mems)
  }

  if (data.ready_to_open) {
    data_round = data.round
    setGameUsers(data.users)

    // Отключаем WebSocket подписку и polling
    if (roundSubscription) {
      console.log("🔗 [handleRoundUpdate] Unsubscribing from round channel - round ready to open")
      roundSubscription.unsubscribe()
      roundSubscription = null
    }
    
    if (timeout_round_wait != null){
      clearInterval(timeout_round_wait)
    }
    
    round_result = data.mems
    showRoundMems()
  }
}

let PROGRESS_INTERVAL = 50
function setRoundProgressLeft(){
  if (timeout_round_wait != null){
    clearInterval(timeout_round_wait)
  }

  timeout_round_wait = setInterval(() => {
    timeout_round_left_ms -= PROGRESS_INTERVAL
    if (timeout_round_left_ms <= 0){
      //window.location.reload()
    }

    progress_line.style.width = timeout_round_left_ms / constants.round_duration * 100 + "%"
  }, PROGRESS_INTERVAL)
}

function setVoteProgressLeft(){
  if (timeout_vote_wait != null){
    clearInterval(timeout_vote_wait)
  }

  timeout_vote_wait = setInterval(() => {
    timeout_vote_left_ms -= PROGRESS_INTERVAL
    if (timeout_vote_left_ms <= 0){
      //window.location.reload()
    }

    progress_line.style.width = timeout_vote_left_ms / constants.vote_duration * 100 + "%"
  }, PROGRESS_INTERVAL)
}

function setRestartProgressLeft(){
  if (timeout_restart_wait != null){
    clearInterval(timeout_restart_wait)
  }

  timeout_restart_wait = setInterval(() => {
    timeout_restart_left_ms -= PROGRESS_INTERVAL
    if (timeout_restart_left_ms <= 0){
      //window.location.reload()
    }

    progress_line.style.width = timeout_restart_left_ms / constants.restart_duration * 100 + "%"
  }, PROGRESS_INTERVAL)
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
  if (!my_mems || !Array.isArray(my_mems)) {
    console.warn("🎮 [setMyMems] my_mems is not a valid array:", my_mems)
    return
  }
  
  let html = ''
  my_mems.forEach(mem => {
    const in_active = mem.active ? "" : `<div class="mem_inactive"></div>`
    const link_video = `https://s3.regru.cloud/mem-assets/videos_small/${mem.name}.mp4`
    const link_image = `https://s3.regru.cloud/mem-assets/covers_small/${mem.name}.webp`
    html += `
    <div class="mem_card" data-name="${mem.name}" data-link-video="${link_video}" data-active="${mem.active}">
      <img src="${link_image}"/>
      ${in_active}
    </div>`
  })

  document.getElementById('div_my_mems').innerHTML = html

  Array.from(document.querySelectorAll("#div_my_mems .mem_card")).forEach(function(element) {
    element.addEventListener("click", onMemClick )
  })
}

function onMemClick(){
  if (this.getAttribute("data-active") === "true") {
    div_video.style.display = "flex"
    my_mem_mp4.src = this.getAttribute("data-link-video")
    btn_send.innerText = "Отправить"
    btn_send.setAttribute("data-mem-name", this.getAttribute("data-name"))
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
  // Отключаем старый polling если он был активен
  if (timeout_vote_wait != null){
    clearInterval(timeout_vote_wait)
  }
  
  progress_comment.innerText = "Голосуем..."

  subscribeToVoteUpdates()
}

// Новая функция для подписки на веб-сокет обновления голосования
function subscribeToVoteUpdates() {
  console.log("🔗 [subscribeToVoteUpdates] Starting WebSocket connection for vote updates...")
  console.log("🔗 [subscribeToVoteUpdates] Game ID:", data_game?.id, "User ID:", user_id)
  
  // Проверяем наличие необходимых данных
  if (!data_game || !data_game.id) {
    console.error("❌ [subscribeToVoteUpdates] No game data available");
    return;
  }
  
  if (!user_id) {
    console.error("❌ [subscribeToVoteUpdates] No user_id available");
    return;
  }
  
  // Отписываемся от предыдущей подписки если она была
  if (voteSubscription) {
    console.log("🔗 [subscribeToVoteUpdates] Unsubscribing from previous subscription")
    voteSubscription.unsubscribe()
    voteSubscription = null
  }

  // Включаем автоматическое переподключение
  actionCableConsumer.shouldReconnect = true;

  // Подключаемся к Action Cable
  console.log("🔗 [subscribeToVoteUpdates] Connecting to Action Cable...")
  actionCableConsumer.connect('/cable', { user_id: user_id })

  // Создаем подписку на VoteChannel
  console.log("🔗 [subscribeToVoteUpdates] Creating subscription to VoteChannel...")
  voteSubscription = actionCableConsumer.subscribe('VoteChannel', {
    game_id: data_game.id
  })

  // Обработчики событий подписки
  voteSubscription.connected = () => {
    console.log("🎮 [subscribeToVoteUpdates] ✅ Connected to vote channel")
  }

  voteSubscription.disconnected = () => {
    console.log("❌ [subscribeToVoteUpdates] Disconnected from vote channel")
  }

  voteSubscription.received = (data) => {
    console.log("🎮 [subscribeToVoteUpdates] WebSocket vote update received:", data)
    handleVoteUpdate(data)
  }
  
  console.log("🔗 [subscribeToVoteUpdates] Subscription setup completed")
}

// Общий обработчик обновлений голосования (для WebSocket и polling)
function handleVoteUpdate(data) {
  console.log("🎮 [handleVoteUpdate] Processing vote update:", data)

  // setGameUsers(data.users)
  setVotes(data.mems)

  container_progress_line.style.display = 'block'
  leaveGame(data.users)

  timeout_vote_left_ms = data.vote_progress_left
  setVoteProgressLeft()

  if (data.vote_finish) {
    // Отключаем WebSocket подписку и polling
    if (voteSubscription) {
      console.log("🔗 [handleVoteUpdate] Unsubscribing from vote channel - voting finished")
      voteSubscription.unsubscribe()
      voteSubscription = null
    }
    
    if (timeout_vote_wait != null){
      clearInterval(timeout_vote_wait)
    }
    
    setGameUsers(data.users)

    if (data.finish_game){
      finishGame()
    } else {
      finishRound()
    }
  }
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
  timeoutRestartWait()

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
  console.log("Wait for restart")
  // Отключаем старый polling если он был активен
  if (timeout_restart_wait != null){
    clearInterval(timeout_restart_wait)
  }

  subscribeToRestartUpdates()
  //subscribeToNewGameUpdates()
}

// Новая функция для подписки на веб-сокет обновления рестарта
function subscribeToRestartUpdates() {
  if (!data_game || !data_game.id) {
    return;
  }
  
  if (!user_id) {
    return;
  }
  
  // Отписываемся от предыдущей подписки если она была
  if (restartSubscription) {
    restartSubscription.unsubscribe()
    restartSubscription = null
  }

  // Включаем автоматическое переподключение
  actionCableConsumer.shouldReconnect = true;

  // Подключаемся к Action Cable
  actionCableConsumer.connect('/cable', { user_id: user_id })

  // Создаем подписку на RestartChannel
  restartSubscription = actionCableConsumer.subscribe('RestartChannel', {
    game_id: data_game.id
  })

  // Обработчики событий подписки
  restartSubscription.connected = () => {
  }

  restartSubscription.disconnected = () => {
  }

  restartSubscription.received = (data) => {
    handleRestartUpdate(data)
  }
}

// Общий обработчик обновлений рестарта (для WebSocket и polling)
function handleRestartUpdate(data) {
  console.log("🔄 [handleRestartUpdate] Processing restart update:", data)

  container_progress_line.style.display = 'block'

  timeout_restart_left_ms = data.restart_progress_left
  setRestartProgressLeft()

  setGameUsers(data.users)
  setUsersRestart(data.game, data.users)

  data.winners_ids.forEach(id => {
    document.querySelector(`.div_player[data-id="${id}"]`).classList.add("winner")
  })

  if (data.ready_to_start) {
    // Отключаем WebSocket подписку и polling
    if (restartSubscription) {
      console.log("🔗 [handleRestartUpdate] Unsubscribing from restart channel - restart finished")
      restartSubscription.unsubscribe()
      restartSubscription = null
    }
    
    if (timeout_restart_wait != null){
      clearInterval(timeout_restart_wait)
    }

    if (data.new_game_users.includes(user_id)) {
      startGame(data.new_game, user_id)
    } else {
      window.location.reload()
    }
  }
}


// Новая функция для подписки на веб-сокет обновления рестарта
function subscribeToNewGameUpdates() {
  if (!data_game || !data_game.id) {
    return;
  }
  
  if (!user_id) {
    return;
  }
  
  // Отписываемся от предыдущей подписки если она была
  if (newGameSubscription) {
    newGameSubscription.unsubscribe()
    newGameSubscription = null
  }

  // Включаем автоматическое переподключение
  actionCableConsumer.shouldReconnect = true;

  // Подключаемся к Action Cable
  actionCableConsumer.connect('/cable', { user_id: user_id })

  // Создаем подписку на RestartChannel
  newGameSubscription = actionCableConsumer.subscribe('NewGameChannel', {
    game_id: data_game.id
  })

  // Обработчики событий подписки
  newGameSubscription.connected = () => {
  }

  newGameSubscription.disconnected = () => {
  }

  newGameSubscription.received = (data) => {
    handleNewGameUpdate(data)
  }
}

// Общий обработчик обновлений рестарта (для WebSocket и polling)
function handleNewGameUpdate(data) {
  if (restartSubscription) {
    restartSubscription.unsubscribe()
    restartSubscription = null
  }
  if (newGameSubscription) {
    newGameSubscription.unsubscribe()
    newGameSubscription = null
  }
  
  if (timeout_restart_wait != null){
    clearInterval(timeout_restart_wait)
  }

  if (data.users_ids.includes(user_id)) {
    startGame(data.game, user_id)
  } else {
    window.location.reload()
  }
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
    container.querySelector('source').src = `https://s3.regru.cloud/mem-assets/videos_small/${item.mem}.mp4`

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
  const labels = ['14.06', '30.06', '14.07', '30.07', '14.08', '30.08', '14.09', '30.09',  '15.10', '30.10',  '15.11', '30.11' ];
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

