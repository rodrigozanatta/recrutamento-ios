//
//  ViewController.swift
//  recrutamento-ios
//
//  Created by Rodrigo Zanatta Silva on 10/09/15.
//  Copyright (c) 2015 Rodrigo Zanatta Silva. All rights reserved.
//

import UIKit

class MovieTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {

    let clientID   = "81d58ede92d7762ca84a017eeebd19902fb36f0ff30647004dbe2b4d19a93bd6"
    var movieNames = [String]()
    var URLImage   = [String:NSString]()
    var imageCache = [String: UIImage]()
    var contPage   = 1

// MARK: - Funções da ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        //Teste simples para saber se tem internet
        if IJReachability.isConnectedToNetwork() {
            loadContent()
        } else {
            //Não é a forma mais correta de tratar quando não há conexão
            let title = "Problema"
            let message = "Internet não esta funcionando. Verifique sua conexão e tente novamente."
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

// MARK: - Funções da TableView
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieNames.count/3
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ThreeMoviesInLine", forIndexPath: indexPath) as! MovieTableViewCell
        let leftTitle   =  movieNames[3 * indexPath.row + 0]
        let centerTitle =  movieNames[3 * indexPath.row + 1]
        let rightTitle  =  movieNames[3 * indexPath.row + 2]

        loadImage(leftTitle, toImageView: cell.leftImage)
        loadImage(centerTitle, toImageView: cell.centerImage)
        loadImage(rightTitle, toImageView: cell.rightImage)

        cell.leftLabel.text   = leftTitle
        cell.centerLabel.text = centerTitle
        cell.rightLabel.text = rightTitle

        return cell
    }

    @IBAction func refreshTable(sender: UIRefreshControl) {
        contPage++
        if contPage>=2 { contPage=2 }  //Não funcionou para a pagina 3, deve ser limitação do servidor
        //Forma porca de atualizar. Apenas porque estava sem tempo
        movieNames.removeAll(keepCapacity: true)
        URLImage.removeAll(keepCapacity: true)
        imageCache.removeAll(keepCapacity: true)
        sender.endRefreshing()
        loadContent()

    }

// MARK: - Funções Auxiliares
    func loadContent() {
        //pegando apenas 5 itens para satisfazer o mockup
        let URL = NSURL(string: "https://api-v2launch.trakt.tv/shows/popular?extended=images&page=\(contPage)&limit=15")
        var request = NSMutableURLRequest(URL: URL!)

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2",                forHTTPHeaderField: "trakt-api-version")
        request.addValue(clientID,           forHTTPHeaderField: "trakt-api-key")

        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue()) { (response, data, error) in
                if data != nil {
                    let json = NSJSONSerialization.JSONObjectWithData(data,
                        options: NSJSONReadingOptions.AllowFragments,
                        error: nil) as! NSArray;
                    for item : AnyObject in json {
                        let title = item["title"] as! String
                        self.movieNames.append(title)
                        //Pega a URL da imagem que esta em dois dicionários aninhados
                        let images = item["images"] as! NSDictionary
                        let poster = images["poster"] as! NSDictionary
                        let thumb = poster["thumb"] as! NSString

                        //Salva a URL da imagem com o nome como chave
                        self.URLImage[title] = thumb

                    }
                    self.tableView.reloadData()
                }
        }
    }

    func loadImage(name: String, toImageView: UIImageView) {
        //Para evitar chamadas na internet, o programa salva as imagens na memória. 
        //Em uma futura versão é aconselhado eliminar imagens em cache a partir de determinado uso
        if let hasCache = imageCache[name] {
            toImageView.image = hasCache
        } else {
            let URLtext = URLImage[name]!
            let URL = NSURL(string: URLtext as String)
            var request = NSMutableURLRequest(URL: URL!)

            NSURLConnection.sendAsynchronousRequest(request,
                queue: NSOperationQueue.mainQueue()) { (response, data, error) in
                    if data != nil {
                        let image:UIImage = UIImage(data: data)!
                        toImageView.image = image
                        self.imageCache[name] = image
                    }
            }
        }
    }


}

