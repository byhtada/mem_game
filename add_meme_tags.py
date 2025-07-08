#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os

def get_meme_tags(mem_name_ru):
    """Создает 3 тэга на английском для мема на основе эмоций, которые он выражает"""
    
    # Словарь соответствий для эмоций в мемах
    emotion_contexts = {
        # Злость/раздражение
        "ну нахер": ["anger", "frustration", "rejection"],
        "пошел на хуй": ["anger", "dismissal", "rage"],
        "сука хитрожопая": ["anger", "irritation", "cunning"],
        "беги сука беги": ["panic", "urgency", "anger"],
        "блядство разврат": ["disgust", "moral-outrage", "criticism"],
        "я тебя сломаю": ["threat", "anger", "aggression"],
        "иди убирай гавно": ["anger", "command", "disgust"],
        "нахуй эту готовку": ["frustration", "anger", "rejection"],
        "что блядь": ["confusion", "anger", "shock"],
        "опа пиздец": ["shock", "surprise", "alarm"],
        "пиздуй отсюда": ["anger", "dismissal", "command"],
        "ля ты крыса": ["anger", "betrayal", "insult"],
        "что с тобой не так": ["frustration", "confusion", "irritation"],
        "тебя никто не спрашивает": ["dismissal", "irritation", "superiority"],
        "иди в жопу": ["anger", "dismissal", "rudeness"],
        
        # Удивление/шок
        "нихуя не понял": ["confusion", "bewilderment", "shock"],
        "что за ужас": ["horror", "shock", "disgust"],
        "упала челюсть": ["shock", "amazement", "surprise"],
        "ядерный взрыв": ["destruction", "shock", "catastrophe"],
        "вы с ума сошли": ["disbelief", "shock", "incredulity"],
        "ой дебил": ["disbelief", "mockery", "superiority"],
        "сказочный долбоеб": ["mockery", "sarcasm", "superiority"],
        "holy shit": ["shock", "surprise", "amazement"],
        "oh my god": ["shock", "surprise", "awe"],
        "что это такое": ["confusion", "bewilderment", "curiosity"],
        "ахуеть": ["shock", "amazement", "disbelief"],
        "вот это поворот": ["surprise", "plot-twist", "amazement"],
        "удивленный мужик": ["surprise", "shock", "bewilderment"],
        
        # Радость/позитив
        "заебись": ["joy", "satisfaction", "approval"],
        "это просто охуенно": ["excitement", "joy", "amazement"],
        "хорошая шутка": ["amusement", "joy", "approval"],
        "lets go": ["excitement", "motivation", "energy"],
        "nice": ["approval", "satisfaction", "positivity"],
        "круто": ["excitement", "approval", "admiration"],
        "реальная тема": ["approval", "satisfaction", "agreement"],
        "заработало": ["joy", "success", "relief"],
        "бесплатное пиво": ["joy", "excitement", "celebration"],
        "хорошенькая": ["admiration", "attraction", "approval"],
        "хороший борщ": ["satisfaction", "pleasure", "comfort"],
        "экстаз": ["ecstasy", "extreme-joy", "euphoria"],
        "бонжур": ["cheerfulness", "greeting", "positivity"],
        
        # Смех/юмор
        "пухлый ржет": ["laughter", "amusement", "joy"],
        "хи-хи ха-ха": ["laughter", "mockery", "amusement"],
        "смешно вам": ["sarcasm", "mockery", "irony"],
        "хорошая шутка": ["amusement", "approval", "joy"],
        "боже какая шутка": ["amusement", "sarcasm", "irony"],
        
        # Грусть/печаль/жалость
        "мальчик обиделся": ["sadness", "offense", "hurt"],
        "нет слов": ["speechlessness", "disappointment", "shock"],
        "его уже никто не найдет": ["sadness", "loss", "despair"],
        "тьфу срамота": ["shame", "disappointment", "disgust"],
        "я худею": ["sadness", "self-pity", "depression"],
        
        # Спокойствие/равнодушие
        "да не бомбит": ["calmness", "denial", "indifference"],
        "ничего страшного": ["reassurance", "calmness", "comfort"],
        "и так сойдет": ["indifference", "acceptance", "resignation"],
        "мне похуй": ["indifference", "detachment", "apathy"],
        "но это не точно": ["uncertainty", "caution", "doubt"],
        "сомнительно но окей": ["skepticism", "reluctant-acceptance", "doubt"],
        "вероятность крайне мала": ["skepticism", "doubt", "pessimism"],
        "подозрительно": ["suspicion", "doubt", "wariness"],
        
        # Страх/беспокойство
        "очкую": ["fear", "anxiety", "nervousness"],
        "страшно очень страшно": ["fear", "terror", "anxiety"],
        "у нас труп": ["fear", "panic", "shock"],
        "нужно успокоительное": ["anxiety", "stress", "nervousness"],
        "мама вызывай гибдд": ["panic", "fear", "emergency"],
        
        # Уверенность/превосходство
        "смекаешь": ["confidence", "superiority", "intelligence"],
        "четко в натуре": ["confidence", "agreement", "certainty"],
        "изи": ["confidence", "ease", "superiority"],
        "лучшая работа в мире": ["pride", "satisfaction", "joy"],
        "духовная скрепа": ["pride", "patriotism", "superiority"],
        "за это похвалю": ["approval", "authority", "satisfaction"],
        
        # Возмущение/негодование
        "это возмутительно": ["outrage", "indignation", "anger"],
        "что за ужас тут творится": ["horror", "outrage", "disgust"],
        "охрененно тупая идея": ["mockery", "superiority", "criticism"],
        "ты втираешь дичь": ["skepticism", "irritation", "dismissal"],
        "сильное заявление": ["sarcasm", "skepticism", "mockery"],
        
        # Усталость/раздражение
        "да ты заебал": ["irritation", "exhaustion", "anger"],
        "я работаю на отъебись": ["apathy", "laziness", "indifference"],
        "давай не будем": ["reluctance", "tiredness", "avoidance"],
        
        # Команды/призывы
        "а ну-ка повтори": ["challenge", "authority", "demand"],
        "давай по новой": ["determination", "restart", "persistence"],
        "слазь": ["command", "authority", "impatience"],
        "иди сюда": ["command", "authority", "call"],
        
        # Персонажи (эмоциональный контекст)
        "сергей дружко": ["confidence", "charisma", "entertainment"],
        "путин": ["authority", "power", "seriousness"],
        "ларин": ["casualness", "youth", "modern"],
        "малышева": ["authority", "medical", "seriousness"],
        "тиньков": ["business", "money", "confidence"]
    }
    
    # Приводим к нижнему регистру для поиска
    name_lower = mem_name_ru.lower()
    
    # Ищем соответствие в словаре эмоций
    for key, emotions in emotion_contexts.items():
        if key in name_lower:
            return emotions
    
    # Если точного соответствия нет, анализируем по ключевым эмоциональным словам
    if any(word in name_lower for word in ["нахуй", "блядь", "сука", "хуй", "пиздец", "ебал"]):
        return ["anger", "frustration", "profanity"]
    elif any(word in name_lower for word in ["хорошо", "отлично", "круто", "заебись", "охуенно"]):
        return ["joy", "satisfaction", "positivity"]
    elif any(word in name_lower for word in ["плохо", "ужас", "дерьмо", "гавно", "срамота"]):
        return ["disgust", "disappointment", "negativity"]
    elif any(word in name_lower for word in ["смех", "ржет", "смешно", "ха-ха", "хи-хи"]):
        return ["laughter", "amusement", "joy"]
    elif any(word in name_lower for word in ["страшно", "боюсь", "ужас", "кошмар"]):
        return ["fear", "anxiety", "terror"]
    elif any(word in name_lower for word in ["что", "как", "где", "когда", "почему", "непонятно"]):
        return ["confusion", "curiosity", "bewilderment"]
    elif any(word in name_lower for word in ["да", "нет", "может", "наверное", "точно"]):
        return ["certainty", "decision", "confidence"]
    elif any(word in name_lower for word in ["грустно", "печально", "жалко", "обиделся"]):
        return ["sadness", "melancholy", "hurt"]
    else:
        return ["neutral", "calm", "expression"]

def process_memes():
    """Обрабатывает JSON файл и добавляет эмоциональные тэги к мемам"""
    
    # Читаем исходный JSON файл
    with open('files/perfect_mem_results.json', 'r', encoding='utf-8') as f:
        memes = json.load(f)
    
    # Получаем список ID мемов из папки covers_small
    covers_dir = 'parsing/covers_small'
    cover_files = os.listdir(covers_dir)
    
    # Извлекаем ID мемов из названий файлов
    available_mem_ids = set()
    for filename in cover_files:
        if filename.startswith('mem_') and filename.endswith('.webp'):
            try:
                mem_id = int(filename.split('_')[1])
                available_mem_ids.add(mem_id)
            except (ValueError, IndexError):
                continue
    
    # Добавляем эмоциональные тэги к мемам, которые есть в папке covers_small
    updated_memes = []
    for meme in memes:
        if meme['mem_id'] in available_mem_ids:
            # Добавляем поле context с эмоциональными тэгами
            meme['context'] = get_meme_tags(meme['mem_name_ru'])
        updated_memes.append(meme)
    
    # Сохраняем обновленный JSON файл
    with open('files/perfect_mem_results_with_emotions.json', 'w', encoding='utf-8') as f:
        json.dump(updated_memes, f, ensure_ascii=False, indent=2)
    
    print(f"Обработано {len(updated_memes)} мемов")
    print(f"Добавлены эмоциональные тэги для {len(available_mem_ids)} мемов из папки covers_small")

if __name__ == "__main__":
    process_memes() 