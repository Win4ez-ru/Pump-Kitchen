import Foundation

struct IngredientLexiconEntry {
    /// Canonical English name the backend search understands.
    let english: String
    /// Display-ready Russian name.
    let russian: String
    /// Lowercase Russian synonyms and colloquial forms.
    let ru: [String]
    /// Extra lowercase English synonyms beyond `english`.
    let en: [String]

    init(_ english: String, _ russian: String, ru: [String], en: [String] = []) {
        self.english = english
        self.russian = russian
        self.ru = ru
        self.en = en
    }
}

enum IngredientLexicon {
    static let entries: [IngredientLexiconEntry] = [
        // Meat & poultry
        .init("chicken breast", "Куриная грудка", ru: ["куриная грудка", "грудка", "куриное филе", "филе курицы", "филе куриное"], en: ["chicken fillet", "chicken breasts"]),
        .init("chicken", "Курица", ru: ["курица", "курочка", "кура", "курятина", "цыпленок"]),
        .init("chicken thighs", "Куриные бедра", ru: ["куриные бедра", "бедра", "бедрышки", "куриные бедрышки"], en: ["chicken thigh"]),
        .init("turkey", "Индейка", ru: ["индейка", "индюшка", "филе индейки"], en: ["turkey breast"]),
        .init("beef", "Говядина", ru: ["говядина", "телятина"], en: ["veal"]),
        .init("ground beef", "Говяжий фарш", ru: ["фарш", "говяжий фарш", "мясной фарш", "фарш говяжий"], en: ["minced beef", "minced meat", "ground meat"]),
        .init("pork", "Свинина", ru: ["свинина"]),
        .init("bacon", "Бекон", ru: ["бекон"]),
        .init("ham", "Ветчина", ru: ["ветчина"]),
        .init("sausage", "Колбаса", ru: ["колбаса", "сосиски", "сосиска", "сардельки"], en: ["sausages"]),
        .init("liver", "Печень", ru: ["печень", "печенка"]),

        // Fish & seafood
        .init("salmon", "Лосось", ru: ["лосось", "семга", "форель"], en: ["trout"]),
        .init("tuna", "Тунец", ru: ["тунец"]),
        .init("cod", "Треска", ru: ["треска", "белая рыба"], en: ["white fish"]),
        .init("shrimp", "Креветки", ru: ["креветки", "креветка"], en: ["shrimps", "prawns"]),
        .init("fish", "Рыба", ru: ["рыба"]),

        // Dairy & eggs
        .init("eggs", "Яйца", ru: ["яйцо", "яйца", "яички"], en: ["egg"]),
        .init("milk", "Молоко", ru: ["молоко"]),
        .init("butter", "Сливочное масло", ru: ["сливочное масло", "масло сливочное"]),
        .init("cheese", "Сыр", ru: ["сыр", "сырок"]),
        .init("cottage cheese", "Творог", ru: ["творог", "творожок"], en: ["curd", "quark"]),
        .init("greek yogurt", "Греческий йогурт", ru: ["греческий йогурт", "йогурт греческий"]),
        .init("yogurt", "Йогурт", ru: ["йогурт"], en: ["yoghurt"]),
        .init("cream", "Сливки", ru: ["сливки"], en: ["heavy cream", "whipping cream"]),
        .init("sour cream", "Сметана", ru: ["сметана"]),
        .init("kefir", "Кефир", ru: ["кефир"]),
        .init("mozzarella", "Моцарелла", ru: ["моцарелла"]),
        .init("parmesan", "Пармезан", ru: ["пармезан"], en: ["parmigiano"]),
        .init("feta", "Фета", ru: ["фета", "брынза"], en: ["feta cheese"]),
        .init("cream cheese", "Сливочный сыр", ru: ["сливочный сыр", "творожный сыр", "филадельфия"]),

        // Grains, pasta & bakery
        .init("rice", "Рис", ru: ["рис", "рисовая крупа"]),
        .init("buckwheat", "Гречка", ru: ["гречка", "гречневая крупа", "греча"]),
        .init("oats", "Овсянка", ru: ["овсянка", "овсяные хлопья", "геркулес", "овес"], en: ["oatmeal", "rolled oats"]),
        .init("pasta", "Макароны", ru: ["макароны", "паста", "макарошки"]),
        .init("spaghetti", "Спагетти", ru: ["спагетти"]),
        .init("noodles", "Лапша", ru: ["лапша"]),
        .init("quinoa", "Киноа", ru: ["киноа"]),
        .init("bulgur", "Булгур", ru: ["булгур"]),
        .init("couscous", "Кускус", ru: ["кускус"]),
        .init("bread", "Хлеб", ru: ["хлеб", "батон", "булка"]),
        .init("flour", "Мука", ru: ["мука"]),
        .init("tortilla", "Тортилья", ru: ["тортилья", "лаваш"], en: ["lavash", "wrap"]),

        // Legumes
        .init("beans", "Фасоль", ru: ["фасоль", "бобы"]),
        .init("chickpeas", "Нут", ru: ["нут", "турецкий горох"], en: ["chickpea", "garbanzo beans"]),
        .init("lentils", "Чечевица", ru: ["чечевица"], en: ["lentil"]),
        .init("peas", "Горошек", ru: ["горошек", "горох", "зеленый горошек"], en: ["green peas"]),

        // Vegetables & greens
        .init("tomatoes", "Помидоры", ru: ["помидор", "помидоры", "томат", "томаты", "помидорка", "черри"], en: ["tomato", "cherry tomatoes"]),
        .init("cucumber", "Огурец", ru: ["огурец", "огурцы", "огурчик"], en: ["cucumbers"]),
        .init("potatoes", "Картофель", ru: ["картошка", "картофель", "картофан"], en: ["potato"]),
        .init("onion", "Лук", ru: ["лук", "луковица", "лук репчатый", "репчатый лук"], en: ["onions"]),
        .init("green onion", "Зеленый лук", ru: ["зеленый лук", "лук зеленый"], en: ["scallions", "spring onion"]),
        .init("garlic", "Чеснок", ru: ["чеснок", "чесночок"]),
        .init("carrot", "Морковь", ru: ["морковь", "морковка"], en: ["carrots"]),
        .init("cabbage", "Капуста", ru: ["капуста"]),
        .init("broccoli", "Брокколи", ru: ["брокколи"]),
        .init("cauliflower", "Цветная капуста", ru: ["цветная капуста", "капуста цветная"]),
        .init("zucchini", "Кабачок", ru: ["кабачок", "кабачки", "цукини"], en: ["courgette"]),
        .init("eggplant", "Баклажан", ru: ["баклажан", "баклажаны"], en: ["aubergine"]),
        .init("bell pepper", "Болгарский перец", ru: ["болгарский перец", "перец болгарский", "сладкий перец", "паприка свежая"], en: ["sweet pepper", "red pepper", "paprika pepper"]),
        .init("chili pepper", "Перец чили", ru: ["чили", "перец чили", "острый перец"], en: ["chili", "hot pepper"]),
        .init("spinach", "Шпинат", ru: ["шпинат"]),
        .init("lettuce", "Салат", ru: ["салат", "листья салата", "салатные листья", "айсберг", "руккола"], en: ["salad greens", "arugula", "rocket"]),
        .init("mushrooms", "Грибы", ru: ["грибы", "гриб", "шампиньоны", "шампиньон", "вешенки"], en: ["mushroom", "champignons"]),
        .init("corn", "Кукуруза", ru: ["кукуруза"]),
        .init("pumpkin", "Тыква", ru: ["тыква"]),
        .init("beets", "Свекла", ru: ["свекла", "буряк"], en: ["beetroot", "beet"]),
        .init("radish", "Редис", ru: ["редис", "редиска"]),
        .init("celery", "Сельдерей", ru: ["сельдерей"]),
        .init("avocado", "Авокадо", ru: ["авокадо"]),
        .init("green beans", "Стручковая фасоль", ru: ["стручковая фасоль", "фасоль стручковая"]),
        .init("ginger", "Имбирь", ru: ["имбирь"]),

        // Fruits & berries
        .init("apple", "Яблоко", ru: ["яблоко", "яблоки"], en: ["apples"]),
        .init("banana", "Банан", ru: ["банан", "бананы"], en: ["bananas"]),
        .init("orange", "Апельсин", ru: ["апельсин", "апельсины"], en: ["oranges"]),
        .init("lemon", "Лимон", ru: ["лимон", "лимончик"], en: ["lemons", "lemon juice"]),
        .init("lime", "Лайм", ru: ["лайм"]),
        .init("pear", "Груша", ru: ["груша", "груши"]),
        .init("grapes", "Виноград", ru: ["виноград"]),
        .init("strawberries", "Клубника", ru: ["клубника"], en: ["strawberry"]),
        .init("blueberries", "Черника", ru: ["черника", "голубика"], en: ["blueberry"]),
        .init("raspberries", "Малина", ru: ["малина"], en: ["raspberry"]),
        .init("peach", "Персик", ru: ["персик", "персики"]),
        .init("pineapple", "Ананас", ru: ["ананас"]),
        .init("mango", "Манго", ru: ["манго"]),
        .init("kiwi", "Киви", ru: ["киви"]),
        .init("watermelon", "Арбуз", ru: ["арбуз"]),
        .init("melon", "Дыня", ru: ["дыня"]),
        .init("pomegranate", "Гранат", ru: ["гранат"]),
        .init("cherry", "Вишня", ru: ["вишня", "черешня"]),
        .init("dried fruits", "Сухофрукты", ru: ["сухофрукты", "изюм", "курага", "чернослив"], en: ["raisins", "dried apricots", "prunes"]),

        // Nuts & seeds
        .init("walnuts", "Грецкие орехи", ru: ["грецкие орехи", "грецкий орех"], en: ["walnut"]),
        .init("almonds", "Миндаль", ru: ["миндаль"], en: ["almond"]),
        .init("peanuts", "Арахис", ru: ["арахис"], en: ["peanut"]),
        .init("cashews", "Кешью", ru: ["кешью"], en: ["cashew"]),
        .init("nuts", "Орехи", ru: ["орехи", "орех", "орешки"]),
        .init("sunflower seeds", "Семечки", ru: ["семечки", "семена подсолнечника"]),
        .init("chia seeds", "Семена чиа", ru: ["чиа", "семена чиа"], en: ["chia"]),
        .init("sesame", "Кунжут", ru: ["кунжут"], en: ["sesame seeds"]),
        .init("peanut butter", "Арахисовая паста", ru: ["арахисовая паста", "арахисовое масло"]),

        // Oils, sauces & condiments
        .init("olive oil", "Оливковое масло", ru: ["оливковое масло", "масло оливковое"], en: ["extra virgin olive oil"]),
        .init("sunflower oil", "Подсолнечное масло", ru: ["подсолнечное масло", "растительное масло", "масло растительное"], en: ["vegetable oil"]),
        .init("coconut oil", "Кокосовое масло", ru: ["кокосовое масло"]),
        .init("vinegar", "Уксус", ru: ["уксус"]),
        .init("soy sauce", "Соевый соус", ru: ["соевый соус", "соус соевый"]),
        .init("honey", "Мед", ru: ["мед", "медок"]),
        .init("sugar", "Сахар", ru: ["сахар", "сахарок"]),
        .init("salt", "Соль", ru: ["соль"]),
        .init("black pepper", "Черный перец", ru: ["черный перец", "перец черный", "перец молотый"], en: ["ground pepper"]),
        .init("mustard", "Горчица", ru: ["горчица"]),
        .init("ketchup", "Кетчуп", ru: ["кетчуп"]),
        .init("mayonnaise", "Майонез", ru: ["майонез", "майонезик"], en: ["mayo"]),
        .init("tomato paste", "Томатная паста", ru: ["томатная паста", "паста томатная"], en: ["tomato sauce", "tomato puree"]),

        // Herbs & spices
        .init("dill", "Укроп", ru: ["укроп"]),
        .init("parsley", "Петрушка", ru: ["петрушка"]),
        .init("basil", "Базилик", ru: ["базилик"]),
        .init("cilantro", "Кинза", ru: ["кинза", "кориандр"], en: ["coriander"]),
        .init("mint", "Мята", ru: ["мята"]),
        .init("rosemary", "Розмарин", ru: ["розмарин"]),
        .init("thyme", "Тимьян", ru: ["тимьян", "чабрец"]),
        .init("paprika", "Паприка", ru: ["паприка"]),
        .init("cinnamon", "Корица", ru: ["корица"]),
        .init("turmeric", "Куркума", ru: ["куркума"]),
        .init("oregano", "Орегано", ru: ["орегано", "душица"]),
        .init("vanilla", "Ваниль", ru: ["ваниль", "ванилин"], en: ["vanilla extract"]),

        // Other
        .init("tofu", "Тофу", ru: ["тофу"]),
        .init("protein powder", "Протеин", ru: ["протеин", "протеиновый порошок"], en: ["whey protein", "protein"]),
        .init("chocolate", "Шоколад", ru: ["шоколад", "шоколадка"], en: ["dark chocolate"]),
        .init("cocoa", "Какао", ru: ["какао"], en: ["cocoa powder"]),
        .init("coffee", "Кофе", ru: ["кофе"]),
        .init("olives", "Оливки", ru: ["оливки", "маслины"]),
        .init("pickles", "Соленые огурцы", ru: ["соленые огурцы", "маринованные огурцы", "соленья"], en: ["pickled cucumbers"]),
        .init("coconut milk", "Кокосовое молоко", ru: ["кокосовое молоко", "молоко кокосовое"]),
        .init("condensed milk", "Сгущенка", ru: ["сгущенка", "сгущенное молоко"]),
        .init("baking powder", "Разрыхлитель", ru: ["разрыхлитель"]),
        .init("yeast", "Дрожжи", ru: ["дрожжи"]),
        .init("gelatin", "Желатин", ru: ["желатин"]),
        .init("water", "Вода", ru: ["вода", "водичка"])
    ]
}
